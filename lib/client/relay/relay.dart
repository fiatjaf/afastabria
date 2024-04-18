import "dart:convert";
import "dart:async";

import "package:loure/main.dart";
import "package:loure/client/event.dart";
import "package:loure/client/filter.dart";
import "package:loure/client/relay/util.dart";
import "package:loure/client/relay/relay_info.dart";

abstract class Relay {
  Relay(this.url, this.relayStatus, this.assumeValid, this.makeAuthEvent) {
    this.url = RelayUtil.normalizeURL(url);
  }
  late String url;
  final RelayStatus relayStatus;
  final bool assumeValid;
  final Event Function(List<List<String>>)? makeAuthEvent;

  RelayInfo? info;

  final Map<String, Subscription> _subscriptions = {};
  final Map<String, Completer<OK>> _published = {};
  final Map<String, Timer> _timers = {};

  int serial = 0;
  String? challenge;
  bool hasAuthed = false;

  Function()? onError;

  Future<bool> connect();

  Subscription subscribe(
    final List<Filter> filters, {
    required final Function(Event) onEvent,
    final Function()? onEose,
    final Function(String)? onClose,
    String? id,
    final bool Function(String?)? intercept,
  }) {
    if (filters.isEmpty) {
      throw ArgumentError("No filters given", "filters");
    }

    id = id != null ? "$id-${this.serial++}" : "sub${this.serial++}";

    final Subscription sub = Subscription(
      this,
      id,
      filters,
      onEvent,
      onEose ?? () => print("eose from $url::$id"),
      onClose ?? (final String msg) => print("closed $url::$id with $msg"),
      intercept,
    );

    _subscriptions[sub.id] = sub;

    sub.fire();
    return sub;
  }

  Subscription subscribeEose(
    final List<Filter> filters, {
    required Function(Event) onEvent,
    final Function(String)? onClose,
    final String? id,
  }) {
    Subscription? internalSub;
    final sub = this.subscribe(filters,
        id: id,
        onEvent: onEvent,
        onEose: () => internalSub!.close("automatically closing on eose"),
        onClose: onClose);
    internalSub = sub;
    return sub;
  }

  void onMessage(final String rawMessage) {
    final subId = RelayUtil.getSubscriptionId(rawMessage);
    final sub = this._subscriptions[subId];
    if (sub != null && sub.intercept != null) {
      final interrupt = sub.intercept!(RelayUtil.getEventId(rawMessage));
      if (interrupt) {
        return;
      }
    }

    try {
      final message = jsonDecode(rawMessage);
      switch (message[0]) {
        case "OK":
          final id = message[1] as String;

          final timer = this._timers.remove(id);
          if (timer != null) timer.cancel();

          final completer = this._published[id];
          if (completer != null) {
            this._published.remove(id);
            completer
                .complete(OK(message[2] as bool, (message[3] ?? "") as String));
          }
          break;
        case "EVENT":
          final subId = message[1] as String;
          final sub = this._subscriptions[subId];
          if (sub == null) {
            return;
          }

          final event = Event.fromJson(message[2]);
          if (sub.filters.any(event.matches) &&
              (this.assumeValid || (event.isValid))) {
            // add some statistics
            this.relayStatus.noteReceived++;

            // check block pubkey
            if (filterProvider.checkBlock(event.pubkey)) {
              return;
            }
            // check dirtyword
            if (filterProvider.checkDirtyword(event.content)) {
              return;
            }

            nostr.updateIndexesAndSource(event, this.url);

            sub.onEvent(event);
          }
          break;
        case "EOSE":
          final subId = message[1] as String;
          final sub = this._subscriptions[subId];
          if (sub != null) {
            sub.eose();
          }
          break;
        case "NOTICE":
          // noticeProvider.onNotice(this.url, message[1] as String);
          break;
        case "CLOSED":
          final subId = message[1] as String;
          final sub = this._subscriptions[subId];
          if (sub != null) {
            final reason = message[2] as String;
            if (reason.startsWith("auth-required: ") &&
                this.challenge != null &&
                this.makeAuthEvent != null &&
                this.hasAuthed == false) {
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

              // mark this so we don't auth infinite times in case the relay is buggy
              this.hasAuthed = true;

              sub.fire(); // try again
            } else {
              // nothing to do, so call close()
              sub.close(reason);
            }
          }
          break;
        case "AUTH":
          this.challenge = message[1] as String;
          break;
      }
    } catch (err) {
      print("[$url]: error receiving message '$rawMessage': $err");
    }
  }

  Future<OK> publish(final Event event) async {
    final completer = Completer<OK>();
    this._published[event.id] = completer;
    this.send(["EVENT", event.toJson()]);
    this._timers[event.id] = Timer(const Duration(seconds: 45), () {
      this._timers.remove(event.id);
      final completer = this._published.remove(event.id);
      if (completer != null) {
        completer.completeError(FormatException(
            "$url took too long to reply with OK for ${event.id}"));
      }
    });
    return completer.future;
  }

  void send(final List<dynamic> message);

  Future<void> disconnect();

  void handleError(final String errMsg) {
    print("[$url]: relay error: $errMsg");
    relayStatus.error++;
    relayStatus.connected = ConnState.DISCONNECTED;
    disconnect();

    if (this.onError != null) this.onError!();
  }

  void dispose() {
    this.disconnect();
  }
}

class Subscription {
  Subscription(this._relay, this.id, this.filters, this.onEvent, this.onEose,
      this.onClose, this.intercept);
  final Relay _relay;
  final String id;
  final List<Filter> filters;
  final Function(Event) onEvent;
  final Function() onEose;
  final Function(String) onClose;
  final bool Function(String?)? intercept;

  bool hasEosed = false;

  void fire() {
    List<dynamic> json = ["REQ", this.id];
    for (final filter in this.filters) {
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

  void close(final String reason) {
    this._relay.send(["CLOSE", this.id]);
    this.eose();
    this.onClose(reason);
  }
}

class RelayStatus {
  RelayStatus(this.addr);
  String addr;
  ConnState connected = ConnState.DISCONNECTED;

  // bool noteAble = true;
  // bool dmAble = true;
  // bool profileAble = true;
  // bool globalAble = true;

  int noteReceived = 0;
  int error = 0;
}

class OK {
  OK(this.ok, this.message);
  final bool ok;
  final String message;
}

enum ConnState {
  DISCONNECTED,
  CONNECTING,
  CONNECTED,
}
