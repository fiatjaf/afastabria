import 'dart:async';
import 'dart:js_interop_unsafe';

import 'package:flutter/material.dart';

import 'package:nostrmo/consts/relay_mode.dart';
import 'package:nostrmo/util/platform_util.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/client/filter.dart';
import 'package:nostrmo/client/event.dart';
import 'package:nostrmo/client/event_kind.dart';
import 'package:nostrmo/client/relay/relay.dart';
import 'package:nostrmo/client/relay/util.dart';
import 'package:nostrmo/client/relay/relay_base.dart';
import 'package:nostrmo/client/relay/relay_isolate.dart';

class RelayProvider extends ChangeNotifier {
  final Map<String, RelayStatus> relayStatusMap = {};

  RelayStatus? getRelayStatus(String url) {
    url = RelayUtil.normalizeURL(url);
    return this.relayStatusMap[url];
  }
}

class RelayPool extends RelayProvider {
  final Map<String, Relay> _relays = {};

  RelayPool();

  Relay ensureRelay(String url) {
    url = RelayUtil.normalizeURL(url);
    var relay = this._relays[url];
    if (relay != null) {
      if (relay.relayStatus.connected == ConnState.UN_CONNECT) {
        this._relays.delete(url);
      } else {
        return relay;
      }
    }

    Event mae(List<List<String>> tags) {
      return Event.finalize(
          nostr.privateKey, EventKind.AUTHENTICATION, tags, "");
    }

    var relayStatus = this.relayStatusMap[url];
    if (relayStatus == null) {
      relayStatus = RelayStatus(url);
      relayStatusMap[url] = relayStatus;
    }

    if (PlatformUtil.isWeb()) {
      // dart:isolate is not supported on dart4web
      relay =
          RelayBase(url, relayStatus, assumeValid: true, makeAuthEvent: mae);
    } else {
      if (settingProvider.relayMode == RelayMode.BASE_MODE) {
        relay =
            RelayBase(url, relayStatus, assumeValid: true, makeAuthEvent: mae);
      } else {
        relay = RelayIsolate(url, relayStatus,
            assumeValid: true, makeAuthEvent: mae);
      }
    }

    this._relays[url] = relay;
    return relay;
  }

  ManySubscriptionHandler subscribeMany(
    Iterable<String> relays,
    List<Filter> filters, {
    Function(Event)? onEvent,
    Function()? onEose,
    Function()? onClose,
    String? id,
  }) {
    onEvent ??= (Event evt) {
      print("received unhandled event $evt");
    };

    relays = relays.map((String url) => RelayUtil.normalizeURL(url)).toList();
    var eosesMissing = relays.toSet();
    var closesMissing = relays.toSet();
    var idsReceived = <String>{};

    return ManySubscriptionHandler(relays.map((String url) {
      var relay = this.ensureRelay(url);
      return relay.subscribe(
        filters,
        onEvent: (Event evt) {
          idsReceived.add(evt.id);
          onEvent!(evt);
        },
        onEose: () {
          if (onEose != null) {
            eosesMissing.delete(url);
            if (eosesMissing.length == 0) {
              onEose();
            }
          }
        },
        onClose: (String msg) {
          if (onClose != null) {
            closesMissing.delete(url);
            if (closesMissing.length == 0) {
              onClose();
            }
          }
        },
        id: id,
        intercept: (String? eventId) {
          if (eventId != null) {
            nostr.eventIndex.update(eventId, (Event evt) {
              evt.sources.add(url);
              return evt;
            });
            if (idsReceived.has(eventId)) {
              return true;
            }
          }
          return false;
        },
      );
    }));
  }

  ManySubscriptionHandler subscribeManyEose(
    Iterable<String> relays,
    List<Filter> filters, {
    Function(Event)? onEvent,
    Function()? onClose,
    String? id,
  }) {
    ManySubscriptionHandler? closeHandle;
    closeHandle =
        this.subscribeMany(relays, filters, onEvent: onEvent, onEose: () {
      closeHandle!.close();
    }, onClose: onClose, id: id);
    return closeHandle;
  }

  Future<Set<Event>> querySync(Iterable<String> relays, Filter filter) async {
    final completer = Completer<Set<Event>>();
    final results = <Event>{};
    this.subscribeManyEose(relays, [filter], onEvent: (Event evt) {
      results.add(evt);
    }, onClose: () {
      completer.complete(results);
    });
    return completer.future;
  }

  Future<Event?> querySingle(Iterable<String> relays, Filter filter) async {
    final completer = Completer<Event>();
    final results = <Event>{};
    this.subscribeManyEose(relays, [filter], onEvent: (Event evt) {
      results.add(evt);
    }, onClose: () {
      if (results.length > 0) {
        completer.complete(
            results.reduce((a, b) => a.createdAt > b.createdAt ? a : b));
      } else {
        completer.completeError(
            FormatException("no events found for $filter on $relays"));
      }
    });
    return completer.future;
  }

  Future<ManyPublishResult> publish(
      Iterable<String> relays, Event event) async {
    var oks = await Future.wait(relays.map((String url) async {
      var relay = this.ensureRelay(url);
      try {
        var ok = await relay.publish(event);
        return ok;
      } catch (err) {
        return OK(false, err.toString());
      }
    }));
    return ManyPublishResult(oks);
  }
}

class ManySubscriptionHandler {
  final Iterable<Subscription> _subscriptions;

  ManySubscriptionHandler(this._subscriptions);

  void close() {
    for (var sub in this._subscriptions) {
      sub.close("close initiated by client");
    }
  }
}

class ManyPublishResult {
  final List<OK> oks;

  ManyPublishResult(this.oks);

  bool get success {
    return this.oks.any((OK ok) => ok.ok);
  }

  bool get failure {
    return !this.success;
  }

  String get successCount {
    var total = this.oks.length;
    var successes = this.oks.where((OK ok) => ok.ok).length;
    return "$successes/$total";
  }
}
