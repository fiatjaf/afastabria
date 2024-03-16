import 'package:flutter/material.dart';

import 'package:loure/client/event.dart';
import 'package:loure/client/event_kind.dart';
import 'package:loure/client/filter.dart';
import 'package:loure/client/nip58/badge_definition.dart';
import 'package:loure/main.dart';
import 'package:loure/util/later_function.dart';

class BadgeDefinitionProvider extends ChangeNotifier with LaterFunction {
  Map<String, BadgeDefinition> map = {};

  BadgeDefinition? get(String badgeId, String pubkey) {
    var bd = map[badgeId];
    if (bd != null) {
      return bd;
    }

    if (!_needUpdatePubKeys.contains(pubkey) &&
        !_handingPubkeys.containsKey(pubkey)) {
      _needUpdatePubKeys.add(pubkey);
    }
    later(_laterCallback, null);
    return null;
  }

  final Map<String, int> _handingPubkeys = {};

  final List<String> _needUpdatePubKeys = [];

  // one user contains multi bedge defintion, here may not works
  final List<Event> _pendingEvents = [];

  void _laterCallback() {
    if (_needUpdatePubKeys.isNotEmpty) {
      _laterSearch();
    }

    if (_pendingEvents.isNotEmpty) {
      _handlePendingEvents();
    }
  }

  void _laterSearch() {
    final filter = Filter(
        kinds: [EventKind.BADGE_DEFINITION], authors: _needUpdatePubKeys);
    nostr.pool.subscribeManyEose(["wss://relay.nostr.band"], [filter],
        onEvent: _onEvent);

    for (var pubkey in _needUpdatePubKeys) {
      _handingPubkeys[pubkey] = 1;
    }
    _needUpdatePubKeys.clear();
  }

  void _onEvent(Event event) {
    _pendingEvents.add(event);
    later(_laterCallback, null);
  }

  void _handlePendingEvents() {
    bool updated = false;

    for (var event in _pendingEvents) {
      var bd = BadgeDefinition.loadFromEvent(event);
      if (bd != null) {
        var badgeId = "30009:${event.pubKey}:${bd.d}";

        var oldBD = map[badgeId];
        if (oldBD == null || oldBD.updatedAt < bd.updatedAt) {
          map[badgeId] = bd;
          updated = true;
        }
      }
    }
    _pendingEvents.clear;

    if (updated) {
      notifyListeners();
    }
  }
}
