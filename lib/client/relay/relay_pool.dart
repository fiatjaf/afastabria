import 'dart:developer';
import 'dart:js_interop_unsafe';

import 'package:nostrmo/consts/relay_mode.dart';
import 'package:nostrmo/util/platform_util.dart';
import 'package:nostrmo/util/string_util.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/client/filter.dart';
import 'package:nostrmo/client/event.dart';
import 'package:nostrmo/client/event_kind.dart';
import 'package:nostrmo/client/relay/relay.dart';
import 'package:nostrmo/client/relay/util.dart';
import 'package:nostrmo/client/relay/relay_base.dart';
import 'package:nostrmo/client/relay/relay_isolate.dart';

class RelayPool {
  final Map<String, Relay> _relays = {};
  final Map<String, RelayStatus> relayStatusMap = {};

  RelayPool();

  Relay ensureRelay(String url) {
    Event mae(List<List<String>> tags) {
      return Event.finalize(
          nostr.privateKey, EventKind.AUTHENTICATION, tags, "");
    }

    var relayStatus = relayStatusMap[url];
    if (relayStatus == null) {
      relayStatus = RelayStatus(url);
      relayStatusMap[url] = relayStatus;
    }

    if (PlatformUtil.isWeb()) {
      // dart:isolate is not supported on dart4web
      return RelayBase(url, relayStatus, assumeValid: true, makeAuthEvent: mae);
    } else {
      if (settingProvider.relayMode == RelayMode.BASE_MODE) {
        return RelayBase(url, relayStatus,
            assumeValid: true, makeAuthEvent: mae);
      } else {
        return RelayIsolate(url, relayStatus,
            assumeValid: true, makeAuthEvent: mae);
      }
    }
  }

  ManySubscriptionHandler subscribeMany(
    List<String> relays,
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

  // different relay use different filter
  String queryByFilters(
      Map<String, List<Filter>> filtersMap, Function(Event) onEvent,
      {String? id, Function? onComplete}) {
    if (filtersMap.isEmpty) {
      throw ArgumentError("No filters given", "filters");
    }
    id ??= StringUtil.rndNameStr(16);
    if (onComplete != null) {
      _queryCompleteCallbacks[id] = onComplete;
    }
    var entries = filtersMap.entries;
    for (var entry in entries) {
      var url = entry.key;
      var filters = entry.value;

      var relay = _relays[url];
      if (relay != null) {
        Subscription subscription = Subscription(filters, onEvent, id);
        relayDoQuery(relay, subscription);
      }
    }
    return id;
  }

  /// query should be a one time filter search.
  /// like: query metadata, query old event.
  /// query info will hold in relay and close in relay when EOSE message be received.
  String query(List<Map<String, dynamic>> filters, Function(Event) onEvent,
      {String? id, Function? onComplete}) {
    if (filters.isEmpty) {
      throw ArgumentError("No filters given", "filters");
    }
    Subscription subscription = Subscription(filters, onEvent, id);
    if (onComplete != null) {
      _queryCompleteCallbacks[subscription.id] = onComplete;
    }
    for (Relay relay in _relays.values) {
      relayDoQuery(relay, subscription);
    }
    return subscription.id;
  }

  bool send(List<String> relays, List<dynamic> message) {
    bool hadSubmitSend = false;

    for (Relay relay in _relays.values) {
      try {
        var result = relay.send(message);
        if (result) {
          hadSubmitSend = true;
        }
      } catch (err) {
        log(err.toString());
        relay.relayStatus.error++;
      }
    }

    return hadSubmitSend;
  }
}

class ManySubscriptionHandler {
  final Iterable<Subscription> _subscriptions;

  ManySubscriptionHandler(this._subscriptions);

  void close() {
    for (var sub in this._subscriptions) {
      sub.close();
    }
  }
}
