import "dart:async";

import "package:flutter/material.dart";

import "package:loure/consts/relay_mode.dart";
import "package:loure/util/platform_util.dart";
import "package:loure/main.dart";
import "package:loure/client/filter.dart";
import "package:loure/client/event.dart";
import "package:loure/client/event_kind.dart";
import "package:loure/client/relay/relay.dart";
import "package:loure/client/relay/util.dart";
import "package:loure/client/relay/relay_base.dart";
import "package:loure/client/relay/relay_isolate.dart";

class RelayProvider extends ChangeNotifier {
  final Map<String, RelayStatus> relayStatusMap = {};

  RelayStatus? getRelayStatus(String url) {
    url = RelayUtil.normalizeURL(url);
    return this.relayStatusMap[url];
  }
}

class RelayPool extends RelayProvider {
  RelayPool();

  final Map<String, Future<Relay>> _relays = {};
  final Set<String> _penaltyBox = {};

  Future<Relay> ensureRelay(String url) async {
    url = RelayUtil.normalizeURL(url);
    if (this._penaltyBox.contains(url)) {
      throw FormatException("$url in penalty box");
    }
    return this._relays.putIfAbsent(url, () async {
      late Relay relay;

      Event mae(final List<List<String>> tags) {
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
          relay = RelayBase(url, relayStatus,
              assumeValid: true, makeAuthEvent: mae);
        } else {
          relay = RelayIsolate(url, relayStatus,
              assumeValid: true, makeAuthEvent: mae);
        }
      }

      relay.onError = () {
        print("$url errored, goes to penalty box for 30 seconds");
        this._penaltyBox.add(url);
        this._relays.remove(url);
        Future.delayed(const Duration(seconds: 30), () {
          this._penaltyBox.remove(url);
        });
      };

      await relay.connect();
      return relay;
    });
  }

  ManySubscriptionHandle subscribeMany(
    Iterable<String> relays,
    final List<Filter> filters, {
    required Function(Event) onEvent,
    final Function()? onEose,
    final Function()? onClose,
    final String? id,
    final List<Filter> Function(String, List<Filter>)? filterModifier,
  }) {
    relays = relays.map(RelayUtil.normalizeURL).toList();
    final eosesMissing = relays.toSet();
    final closesMissing = relays.toSet();
    final idsReceived = <String>{};

    final subscriptionFutures = relays.map((final String url) async {
      final relay = await this.ensureRelay(url);

      if (filterModifier != null) {
        filterModifier(url, filters);
      }

      return relay.subscribe(
        filters,
        onEvent: (final Event evt) {
          idsReceived.add(evt.id);
          onEvent(evt);
        },
        onEose: () {
          if (onEose != null) {
            eosesMissing.remove(url);
            if (eosesMissing.length == 0) {
              onEose();
            }
          }
        },
        onClose: (final String msg) {
          if (onClose != null) {
            closesMissing.remove(url);
            if (closesMissing.length == 0) {
              onClose();
            }
          }
        },
        id: id,
        intercept: (final String? eventId) {
          if (eventId != null) {
            try {
              nostr.idIndex.update(eventId, (final Event evt) {
                evt.sources.add(url);
                return evt;
              });
              if (idsReceived.contains(eventId)) {
                return true;
              }
            } catch (err) {/***/}
          }
          return false;
        },
      );
    }).toList();

    return ManySubscriptionHandle(subscriptionFutures);
  }

  ManySubscriptionHandle subscribeManyEose(
    final Iterable<String> relays,
    final List<Filter> filters, {
    required final Function(Event) onEvent,
    final Function()? onClose,
    final String? id,
    final List<Filter> Function(String, List<Filter>)? filterModifier,
  }) {
    ManySubscriptionHandle? closeHandle;
    closeHandle =
        this.subscribeMany(relays, filters, onEvent: onEvent, onEose: () {
      closeHandle!.close();
    }, onClose: onClose, id: id, filterModifier: filterModifier);
    return closeHandle;
  }

  Future<Set<Event>> querySync(
    final Iterable<String> relays,
    final Filter filter, {
    final String? id,
    final List<Filter> Function(String, List<Filter>)? filterModifier,
  }) async {
    final completer = Completer<Set<Event>>();
    final results = <Event>{};
    this.subscribeManyEose(relays, [filter], onEvent: (final Event evt) {
      results.add(evt);
    }, onClose: () {
      completer.complete(results);
    }, id: id, filterModifier: filterModifier);
    return completer.future;
  }

  Future<Event?> querySingle(
    final Iterable<String> relays,
    final Filter filter, {
    final String? id,
    final List<Filter> Function(String, List<Filter>)? filterModifier,
  }) async {
    final completer = Completer<Event>();
    Event? result;
    this.subscribeManyEose(relays, [filter], onEvent: (final Event evt) {
      if (result == null || evt.createdAt > result!.createdAt) {
        result = evt;
      }
    }, onClose: () {
      completer.complete(result);
    }, id: id, filterModifier: filterModifier);
    return completer.future;
  }

  Future<ManyPublishResult> publish(
      final Iterable<String> relays, final Event event) async {
    final oks = await Future.wait(relays.map((final String url) async {
      final relay = await this.ensureRelay(url);
      try {
        final ok = await relay.publish(event);
        return ok;
      } catch (err) {
        return OK(false, err.toString());
      }
    }));
    return ManyPublishResult(oks);
  }
}

class ManySubscriptionHandle {
  ManySubscriptionHandle(this._subfutures);
  final Iterable<Future<Subscription>> _subfutures;

  void close() {
    for (final subf in this._subfutures) {
      subf.then((sub) {
        sub.close("close initiated by client");
      });
    }
  }
}

class ManyPublishResult {
  ManyPublishResult(this.oks);
  final List<OK> oks;

  bool get success {
    return this.oks.any((final OK ok) => ok.ok);
  }

  bool get failure {
    return !this.success;
  }

  String get successCount {
    final total = this.oks.length;
    final successes = this.oks.where((final OK ok) => ok.ok).length;
    return "$successes/$total";
  }
}
