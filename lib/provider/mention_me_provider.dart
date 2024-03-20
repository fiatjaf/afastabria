import "package:flutter/material.dart";

import "package:loure/client/event_kind.dart";
import "package:loure/client/event.dart";
import "package:loure/client/filter.dart";
import "package:loure/client/relay/relay_pool.dart";
import "package:loure/data/event_mem_box.dart";
import "package:loure/main.dart";
import "package:loure/util/pendingevents_later_function.dart";

class MentionMeProvider extends ChangeNotifier with PendingEventsLaterFunction {
  MentionMeProvider() {
    _initTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    eventBox = EventMemBox();
  }
  late int _initTime;
  late EventMemBox eventBox;

  void refresh() {
    _initTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    eventBox.clear();
    doQuery();

    mentionMeNewProvider.clear();
  }

  int lastTime() {
    return _initTime;
  }

  ManySubscriptionHandle? subHandle;

  void doQuery({final int? until}) {
    if (this.subHandle != null) {
      this.subHandle!.close();
    }

    final filter = Filter(
      kinds: [
        EventKind.TEXT_NOTE,
        EventKind.REPOST,
        EventKind.BADGE_AWARD,
        EventKind.GENERIC_REPOST,
        EventKind.ZAP,
        EventKind.LONG_FORM,
      ],
      until: until ?? _initTime,
      limit: 50,
      p: [nostr.publicKey],
    );

    final relays = [...nostr.relayList.read];
    List<Filter> Function(String, List<Filter>)? filterModifier;

    if (!this.eventBox.isEmpty()) {
      final oldestCreatedAts = this.eventBox.oldestCreatedAtByRelay(relays);
      filterModifier = (final url, final filters) {
        filters[0].until = oldestCreatedAts.createdAtMap[url] ?? until;
        return filters;
      };
    }

    pool.querySync(relays, filter, filterModifier: filterModifier);
  }

  void onEvent(final Event event) {
    later(event, (final list) {
      final result = eventBox.addList(list);
      if (result) {
        notifyListeners();
      }
    }, null);
  }

  void clear() {
    eventBox.clear();
    notifyListeners();
  }

  void mergeNewEvent() {
    final allEvents = mentionMeNewProvider.eventMemBox.all();

    eventBox.addList(allEvents);
    eventBox.sort();
    mentionMeNewProvider.clear();

    // update ui
    notifyListeners();
  }
}
