import "package:flutter/material.dart";

import "package:loure/client/event.dart";
import "package:loure/client/event_kind.dart";
import "package:loure/client/filter.dart";
import "package:loure/client/relay/relay_pool.dart";
import "package:loure/data/event_mem_box.dart";
import "package:loure/main.dart";
import "package:loure/util/pendingevents_later_function.dart";

class MentionMeNewProvider extends ChangeNotifier
    with PendingEventsLaterFunction {
  EventMemBox eventMemBox = EventMemBox();
  int? _localSince;
  String? subscribeId;

  ManySubscriptionHandle? subHandle;

  void queryNew() {
    _localSince =
        _localSince == null || mentionMeProvider.lastTime() > _localSince!
            ? mentionMeProvider.lastTime()
            : _localSince;

    final filter = Filter(
      since: _localSince! + 1,
      kinds: [
        EventKind.TEXT_NOTE,
        EventKind.REPOST,
        EventKind.BADGE_AWARD,
        EventKind.GENERIC_REPOST,
        EventKind.LONG_FORM,
      ],
      p: [nostr.publicKey],
    );

    this.subHandle = pool.subscribeMany(["wss://relay.nostr.band"], [filter],
        onEvent: (final event) {
      later(event, handleEvents, null);
    });
  }

  handleEvents(final List<Event> events) {
    eventMemBox.addList(events);
    _localSince = eventMemBox.newestEvent!.createdAt;
    notifyListeners();
  }

  void clear() {
    eventMemBox.clear();
    if (this.subHandle != null) this.subHandle!.close();
    notifyListeners();
  }
}
