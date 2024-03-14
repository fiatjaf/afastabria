import 'package:flutter/material.dart';

import 'package:nostrmo/client/event.dart';
import 'package:nostrmo/client/event_kind.dart' as kind;
import 'package:nostrmo/client/filter.dart';
import 'package:nostrmo/client/nip58/badge_definition.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/util/later_function.dart';
import 'package:nostrmo/util/string_util.dart';

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
  final List<Event> _penddingEvents = [];

  void _laterCallback() {
    if (_needUpdatePubKeys.isNotEmpty) {
      _laterSearch();
    }

    if (_penddingEvents.isNotEmpty) {
      _handlePenddingEvents();
    }
  }

  void _laterSearch() {
    List<Map<String, dynamic>> filters = [];
    for (var pubkey in _needUpdatePubKeys) {
      var filter =
          Filter(kinds: [kind.EventKind.BADGE_DEFINITION], authors: [pubkey]);
      filters.add(filter.toJson());
    }
    var subscriptId = StringUtil.rndNameStr(16);
    // use query and close after EOSE
    nostr.query(filters, _onEvent, id: subscriptId);

    for (var pubkey in _needUpdatePubKeys) {
      _handingPubkeys[pubkey] = 1;
    }
    _needUpdatePubKeys.clear();
  }

  void _onEvent(Event event) {
    _penddingEvents.add(event);
    later(_laterCallback, null);
  }

  void _handlePenddingEvents() {
    bool updated = false;

    for (var event in _penddingEvents) {
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
    _penddingEvents.clear;

    if (updated) {
      notifyListeners();
    }
  }
}
