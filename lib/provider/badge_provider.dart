import "package:flutter/material.dart";
import "package:loure/client/event.dart";

import "package:loure/client/event_kind.dart";
import "package:loure/client/filter.dart";
import "package:loure/client/relay/relay_pool.dart";
import "package:loure/main.dart";

class BadgeProvider extends ChangeNotifier {
  Event? badgeEvent;

  ManySubscriptionHandle? subHandle;

  void init() {
    this.subHandle = pool.subscribeMany(
        nostr.relayList.write,
        [
          Filter(authors: [nostr.publicKey], kinds: [EventKind.BADGE_ACCEPT])
        ],
        onEvent: onEvent);
  }

  void reload() {
    if (this.subHandle != null) {
      this.subHandle!.close();
    }
    this.init();
  }

  void wear(final String badgeId, final String eventId,
      {final String? relayAddr}) {
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
    final eList = ["e", eventId];
    if (relayAddr != null) {
      eList.add(relayAddr);
    }
    tags.add(eList);

    this.badgeEvent = nostr.sendList(EventKind.BADGE_ACCEPT, tags, content);

    this._parseProfileBadge();
    this.notifyListeners();
  }

  void onEvent(final Event event) {
    if (badgeEvent == null || event.createdAt > badgeEvent!.createdAt) {
      this.badgeEvent = event;
      this._parseProfileBadge();
      this.notifyListeners();
    }
  }

  Map<String, int> _badgeIdsMap = {};

  void _parseProfileBadge() {
    if (badgeEvent != null) {
      final badgeIds = parseProfileBadge(badgeEvent!);
      _badgeIdsMap = {};
      for (final badgeId in badgeIds) {
        _badgeIdsMap[badgeId] = 1;
      }
    }
  }

  bool containBadge(final String badgeId) {
    if (_badgeIdsMap[badgeId] != null) {
      return true;
    }

    return false;
  }

  static List<String> parseProfileBadge(final Event event) {
    List<String> badgeIds = [];

    for (final tag in event.tags) {
      if (tag[0] == "a") {
        final badgeId = tag[1];

        badgeIds.add(badgeId);
      }
    }

    return badgeIds;
  }
}
