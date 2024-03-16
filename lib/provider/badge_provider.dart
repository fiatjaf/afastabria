import 'package:flutter/material.dart';
import 'package:loure/client/event.dart';

import 'package:loure/client/event_kind.dart';
import 'package:loure/client/filter.dart';
import 'package:loure/main.dart';

class BadgeProvider extends ChangeNotifier {
  Event? badgeEvent;

  void wear(String badgeId, String eventId, {String? relayAddr}) {
    String content = "";
    List<List<String>> tags = [];

    if (badgeEvent != null) {
      content = badgeEvent!.content;
      tags = badgeEvent!.tags;
    } else {
      tags = [
        ["d", "profile_badges"]
      ];
    }

    tags.add(["a", badgeId]);
    var eList = ["e", eventId];
    if (relayAddr != null) {
      eList.add(relayAddr);
    }
    tags.add(eList);

    this.badgeEvent = nostr.sendList(EventKind.BADGE_ACCEPT, tags, content);

    this._parseProfileBadge();
    this.notifyListeners();
  }

  void reload() {
    var filter =
        Filter(authors: [nostr.publicKey], kinds: [EventKind.BADGE_ACCEPT]);

    pool.subscribeMany(nostr.relayList.write, [filter], onEvent: onEvent);
  }

  void onEvent(Event event) {
    if (badgeEvent == null || event.createdAt > badgeEvent!.createdAt) {
      this.badgeEvent = event;
      this._parseProfileBadge();
      this.notifyListeners();
    }
  }

  Map<String, int> _badgeIdsMap = {};

  void _parseProfileBadge() {
    if (badgeEvent != null) {
      var badgeIds = parseProfileBadge(badgeEvent!);
      _badgeIdsMap = {};
      for (var badgeId in badgeIds) {
        _badgeIdsMap[badgeId] = 1;
      }
    }
  }

  bool containBadge(String badgeId) {
    if (_badgeIdsMap[badgeId] != null) {
      return true;
    }

    return false;
  }

  static List<String> parseProfileBadge(Event event) {
    List<String> badgeIds = [];

    for (var tag in event.tags) {
      if (tag[0] == "a") {
        var badgeId = tag[1];

        badgeIds.add(badgeId);
      }
    }

    return badgeIds;
  }
}
