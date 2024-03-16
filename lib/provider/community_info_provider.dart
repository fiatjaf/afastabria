import 'package:flutter/material.dart';
import 'package:loure/client/aid.dart';
import 'package:loure/client/event.dart';
import 'package:loure/client/nip172/community_info.dart';

import 'package:loure/client/filter.dart';
import 'package:loure/main.dart';
import 'package:loure/util/later_function.dart';

class CommunityInfoProvider extends ChangeNotifier with LaterFunction {
  final Map<String, CommunityInfo> _cache = {};

  final Map<String, int> _handingIds = {};

  final List<String> _needPullIds = [];

  final List<Event> _pendingEvents = [];

  CommunityInfo? getCommunity(String aid) {
    var ci = _cache[aid];
    if (ci != null) {
      return ci;
    }

    // add to query
    if (!_handingIds.containsKey(aid) && !_needPullIds.contains(aid)) {
      _needPullIds.add(aid);
    }
    later(_laterCallback, null);

    return null;
  }

  void _laterCallback() {
    if (_needPullIds.isNotEmpty) {
      _laterSearch();
    }

    if (_pendingEvents.isNotEmpty) {
      _handlePendingEvents();
    }
  }

  void _laterSearch() {
    List<Filter> filters = [];
    for (var idStr in _needPullIds) {
      var aId = AId.fromString(idStr);
      if (aId == null) {
        continue;
      }

      filters.add(aId.toFilter());
    }

    nostr.pool.subscribeManyEose(["wss://relay.nostr.band"], filters,
        onEvent: _onEvent);

    for (var pubkey in _needPullIds) {
      _handingIds[pubkey] = 1;
    }
    _needPullIds.clear();
  }

  void _onEvent(Event event) {
    _pendingEvents.add(event);
    later(_laterCallback, null);
  }

  void _handlePendingEvents() {
    bool updated = false;

    for (var event in _pendingEvents) {
      var communityInfo = CommunityInfo.fromEvent(event);
      if (communityInfo != null) {
        var aid = communityInfo.aId.toTag();
        var oldInfo = _cache[aid];
        if (oldInfo == null || oldInfo.createdAt < communityInfo.createdAt) {
          _cache[aid] = communityInfo;
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
