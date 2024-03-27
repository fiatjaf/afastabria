import "package:flutter/material.dart";

import "package:loure/client/event.dart";
import "package:loure/client/input.dart";
import "package:loure/client/nip172/community_info.dart";
import "package:loure/client/filter.dart";
import "package:loure/util/later_function.dart";
import "package:loure/main.dart";

class CommunityInfoProvider extends ChangeNotifier with LaterFunction {
  final Map<String, CommunityInfo> _cache = {};
  final Map<String, int> _handingIds = {};
  final List<String> _needPullIds = [];
  final List<Event> _pendingEvents = [];

  CommunityInfo? getCommunity(final String aid) {
    final ci = _cache[aid];
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
    for (final idStr in _needPullIds) {
      final aId = AddressPointer.fromTag(["", idStr]);
      if (aId == null) {
        continue;
      }

      filters.add(aId.toFilter());
    }

    pool.subscribeManyEose(["wss://relay.nostr.band"], filters,
        onEvent: _onEvent);

    for (final pubkey in _needPullIds) {
      _handingIds[pubkey] = 1;
    }
    _needPullIds.clear();
  }

  void _onEvent(final Event event) {
    _pendingEvents.add(event);
    later(_laterCallback, null);
  }

  void _handlePendingEvents() {
    bool updated = false;

    for (final event in _pendingEvents) {
      final communityInfo = CommunityInfo.fromEvent(event);
      if (communityInfo != null) {
        final aid = communityInfo.aId.toTag();
        final oldInfo = _cache[aid];
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
