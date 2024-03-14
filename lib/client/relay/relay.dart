import 'dart:convert';
import 'dart:developer';
import 'dart:async';
import 'dart:js_interop_unsafe';

import 'package:nostrmo/main.dart';
import 'package:nostrmo/client/event.dart';
import 'package:nostrmo/client/filter.dart';

import 'util.dart';
import 'relay_info.dart';
import 'relay_info_util.dart';

abstract class Relay {
  late String url;
  final RelayStatus relayStatus;
  final bool assumeValid;
  final Event Function(List<List<String>>)? makeAuthEvent;

  RelayInfo? info;

  final Map<String, Subscription> _subscriptions = {};
  final Map<String, Completer<OK>> _published = {};

  int serial = 0;
  String? challenge;

  Relay(this.url, this.relayStatus, this.assumeValid, this.makeAuthEvent) {
    this.url = RelayUtil.normalizeURL(url);
  }

  Future<bool> connect() async {
    try {
      return await doConnect();
    } catch (e) {
      print("connect fail");
      disconnect();
      return false;
    }
  }

  Subscription subscribe(
    List<Filter> filters, {
    Function(Event)? onEvent,
    Function()? onEose,
    Function(String)? onClose,
    String? id,
    bool Function(String?)? intercept,
  }) {
    if (filters.isEmpty) {
      throw ArgumentError("No filters given", "filters");
    }

    id = id ?? "sub${this.serial++}";

    final Subscription sub = Subscription(
      this,
      id,
      filters,
      onEvent ?? (Event evt) => log("$evt from $url::$id"),
      onEose ?? () => log("eose from $url::$id"),
      onClose ?? (String msg) => log("closed $url::$id with $msg"),
      intercept,
    );
    _subscriptions[sub.id] = sub;
    sub.fire();
    return sub;
  }

  Subscription subscribeEose(List<Filter> filters,
      {Function(Event)? onEvent, Function(String)? onClose, String? id}) {
    Subscription? internalSub;
    final sub = this.subscribe(filters,
        id: id,
        onEvent: onEvent,
        onEose: () => internalSub!.close("automatically closing on eose"),
        onClose: onClose);
    internalSub = sub;
    return sub;
  }

  void onMessage(String rawMessage) {
    var subId = RelayUtil.getSubscriptionId(rawMessage);
    var sub = this._subscriptions[subId];
    if (sub != null && sub.intercept != null) {
      var interrupt = sub.intercept!(RelayUtil.getEventId(rawMessage));
      if (interrupt) {
        return;
      }
    }

    try {
      var message = jsonDecode(rawMessage);
      switch (message[0]) {
        case 'OK':
          final id = message[1] as String;

          nostr.eventIndex.update(id, (Event evt) {
            evt.sources.add(this.url);
            return evt;
          });

          final completer = this._published[id];
          if (completer != null) {
            this._published.delete(id);
            completer
                .complete(OK(message[2] as bool, (message[3] ?? "") as String));
          }
          break;
        case 'EVENT':
          final subId = message[1] as String;
          var sub = this._subscriptions[subId];
          if (sub == null) {
            return;
          }

          final event = Event.fromJson(message[2]);
          if (this.assumeValid || (event.isValid)) {
            // add some statistics
            this.relayStatus.noteReceived++;

            // check block pubkey
            if (filterProvider.checkBlock(event.pubKey)) {
              return;
            }
            // check dirtyword
            if (filterProvider.checkDirtyword(event.content)) {
              return;
            }

            nostr.eventIndex.update(event.id, (Event curr) {
              curr.sources.add(this.url);
              return curr;
            }, ifAbsent: () {
              event.sources.add(this.url);
              return event;
            });

            sub.onEvent(event);
          }
          break;
        case 'EOSE':
          final subId = message[1] as String;
          var sub = this._subscriptions[subId];
          if (sub != null) {
            sub.eose();
          }
          break;
        case 'NOTICE':
          noticeProvider.onNotice(this.url, message[1] as String);
          break;
        case 'CLOSED':
          final subId = message[1] as String;
          var sub = this._subscriptions[subId];
          if (sub != null) {
            final reason = message[2] as String;
            if (reason.startsWith("auth-required: ") &&
                this.challenge != null &&
                this.makeAuthEvent != null &&
                sub.hasAuthed == false) {
              // relay is requesting auth for this subscription, so perform auth and try again
              this.send([
                "AUTH",
                this
                    .makeAuthEvent!([
                      ["relay", this.relayStatus.addr],
                      ["challenge", this.challenge!]
                    ])
                    .toJson()
              ]);
              sub.hasAuthed =
                  true; // mark this so we don't auth infinite times in case the relay is buggy
              sub.fire(); // try again
            } else {
              // nothing to do, so call close()
              sub.close(reason);
            }
          }
          break;
        case 'AUTH':
          this.challenge = message[1] as String;
          break;
      }
    } catch (err) {
      log("error receiving message '$rawMessage' from $url: $err");
    }
  }

  Future<bool> doConnect();

  Future<void> getRelayInfo(url) async {
    info ??= await RelayInfoUtil.get(url);
  }

  Future<OK> publish(Event event) async {
    final completer = Completer<OK>();
    this._published[event.id] = completer;
    this.send(["EVENT", event.toJson()]);
    Future.delayed(const Duration(seconds: 45), () {
      this._published.delete(event.id);
      completer.completeError(FormatException(
          "$url took too long to reply with OK for ${event.id}"));
    });
    return completer.future;
  }

  void send(List<dynamic> message);

  Future<void> disconnect();

  bool _waitingReconnect = false;

  void onError(String errMsg, {bool reconnect = false}) {
    print("relay error $errMsg");
    relayStatus.error++;
    relayStatus.connected = ConnState.UN_CONNECT;
    if (relayStatusCallback != null) {
      relayStatusCallback!();
    }
    disconnect();

    if (reconnect && !_waitingReconnect) {
      _waitingReconnect = true;
      Future.delayed(const Duration(seconds: 30), () {
        _waitingReconnect = false;
        connect();
      });
    }
  }

  void saveQuery(Subscription subscription) {
    _subscriptions[subscription.id] = subscription;
  }

  bool checkAndCompleteQuery(String id) {
    // all subscription should be close
    var sub = _subscriptions.remove(id);
    if (sub != null) {
      send(["CLOSE", id]);
      return true;
    }
    return false;
  }

  bool checkQuery(String id) {
    return _subscriptions[id] != null;
  }

  Function? relayStatusCallback;

  void dispose() {}
}

class Subscription {
  final Relay _relay;
  final String id;
  final List<Filter> filters;
  final Function(Event) onEvent;
  final Function() onEose;
  final Function(String) onClose;
  final bool Function(String?)? intercept;

  bool hasEosed = false;
  bool hasAuthed = false;

  Subscription(this._relay, this.id, this.filters, this.onEvent, this.onEose,
      this.onClose, this.intercept);

  void fire() {
    List<dynamic> json = ["REQ", this.id];
    for (Filter filter in this.filters) {
      json.add(filter.toJson());
    }
    this._relay.send(json);
  }

  void eose() {
    if (!this.hasEosed) {
      this.onEose();
      this.hasEosed = true;
    }
  }

  void close(String reason) {
    this._relay.send(["CLOSE", this.id]);
    this.eose();
    this.onClose(reason);
  }
}

class RelayStatus {
  String addr;

  RelayStatus(this.addr);

  int connected = ConnState.UN_CONNECT;

  // bool noteAble = true;
  // bool dmAble = true;
  // bool profileAble = true;
  // bool globalAble = true;

  int noteReceived = 0;
  int error = 0;
}

class OK {
  final bool ok;
  final String message;

  OK(this.ok, this.message);
}

class ConnState {
  static int UN_CONNECT = -1;
  static int CONNECTING = 1;
  static int CONNECTED = 2;
}
