import 'dart:async';

import 'package:flutter/material.dart';

import 'package:loure/consts/relay_mode.dart';
import 'package:loure/util/platform_util.dart';
import 'package:loure/main.dart';
import 'package:loure/client/filter.dart';
import 'package:loure/client/event.dart';
import 'package:loure/client/event_kind.dart';
import 'package:loure/client/relay/relay.dart';
import 'package:loure/client/relay/util.dart';
import 'package:loure/client/relay/relay_base.dart';
import 'package:loure/client/relay/relay_isolate.dart';

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
        this._relays.remove(url);
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

  ManySubscriptionHandle subscribeMany(
    Iterable<String> relays,
    List<Filter> filters, {
    Function(Event)? onEvent,
    Function()? onEose,
    Function()? onClose,
    String? id,
    List<Filter> Function(String, List<Filter>)? filterModifier,
  }) {
    onEvent ??= (Event evt) {
      print("received unhandled event $evt");
    };

    relays = relays.map((String url) => RelayUtil.normalizeURL(url)).toList();
    var eosesMissing = relays.toSet();
    var closesMissing = relays.toSet();
    var idsReceived = <String>{};

    return ManySubscriptionHandle(relays.map((String url) {
      var relay = this.ensureRelay(url);

      if (filterModifier != null) {
        filterModifier(url, filters);
      }

      return relay.subscribe(
        filters,
        onEvent: (Event evt) {
          idsReceived.add(evt.id);
          onEvent!(evt);
        },
        onEose: () {
          if (onEose != null) {
            eosesMissing.remove(url);
            if (eosesMissing.length == 0) {
              onEose();
            }
          }
        },
        onClose: (String msg) {
          if (onClose != null) {
            closesMissing.remove(url);
            if (closesMissing.length == 0) {
              onClose();
            }
          }
        },
        id: id,
        intercept: (String? eventId) {
          if (eventId != null) {
            nostr.idIndex.update(eventId, (Event evt) {
              evt.sources.add(url);
              return evt;
            });
            if (idsReceived.contains(eventId)) {
              return true;
            }
          }
          return false;
        },
      );
    }));
  }

  ManySubscriptionHandle subscribeManyEose(
    Iterable<String> relays,
    List<Filter> filters, {
    Function(Event)? onEvent,
    Function()? onClose,
    String? id,
    List<Filter> Function(String, List<Filter>)? filterModifier,
  }) {
    ManySubscriptionHandle? closeHandle;
    closeHandle =
        this.subscribeMany(relays, filters, onEvent: onEvent, onEose: () {
      closeHandle!.close();
    }, onClose: onClose, id: id, filterModifier: filterModifier);
    return closeHandle;
  }

  Future<Set<Event>> querySync(
    Iterable<String> relays,
    Filter filter, {
    String? id,
    List<Filter> Function(String, List<Filter>)? filterModifier,
  }) async {
    final completer = Completer<Set<Event>>();
    final results = <Event>{};
    this.subscribeManyEose(relays, [filter], onEvent: (Event evt) {
      results.add(evt);
    }, onClose: () {
      completer.complete(results);
    }, id: id, filterModifier: filterModifier);
    return completer.future;
  }

  Future<Event?> querySingle(
    Iterable<String> relays,
    Filter filter, {
    String? id,
    List<Filter> Function(String, List<Filter>)? filterModifier,
  }) async {
    final completer = Completer<Event>();
    Event? result;
    this.subscribeManyEose(relays, [filter], onEvent: (Event evt) {
      if (result == null || evt.createdAt > result!.createdAt) {
        result = evt;
      }
    }, onClose: () {
      completer.complete(result);
    }, id: id, filterModifier: filterModifier);
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

class ManySubscriptionHandle {
  final Iterable<Subscription> _subscriptions;

  ManySubscriptionHandle(this._subscriptions);

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
