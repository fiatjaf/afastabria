import 'package:flutter/material.dart';
import 'package:loure/client/event.dart';

import 'package:loure/client/event_kind.dart' as kind;
import 'package:loure/client/filter.dart';
import 'package:loure/client/nostr.dart';
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

    var newEvent = Event.finalize(
        nostr.privateKey, kind.EventKind.BADGE_ACCEPT, tags, content);

    var result = nostr.broadcast(newEvent);
    badgeEvent = result;
    _parseProfileBadge();
    notifyListeners();
  }

  void reload({bool initQuery = false, Nostr? targetNostr}) {
    targetNostr ??= nostr;

    String? pubkey;
    pubkey = targetNostr.publicKey;

    if (pubkey == null) {
      return;
    }

    var filter =
        Filter(authors: [pubkey], kinds: [kind.EventKind.BADGE_ACCEPT]);
    if (initQuery) {
      targetNostr.addInitQuery([filter], onEvent);
    } else {
      targetNostr.query([filter.toJson()], onEvent);
    }
  }

  void onEvent(Event event) {
    if (badgeEvent == null || event.createdAt > badgeEvent!.createdAt) {
      badgeEvent = event;
      _parseProfileBadge();
      notifyListeners();
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
