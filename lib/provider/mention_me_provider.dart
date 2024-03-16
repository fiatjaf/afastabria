import 'package:flutter/material.dart';

import 'package:loure/client/event_kind.dart';
import 'package:loure/client/event.dart';
import 'package:loure/client/filter.dart';
import 'package:loure/client/relay/relay_pool.dart';
import 'package:loure/data/event_mem_box.dart';
import 'package:loure/main.dart';
import 'package:loure/util/pendingevents_later_function.dart';

class MentionMeProvider extends ChangeNotifier with PendingEventsLaterFunction {
  late int _initTime;
  late EventMemBox eventBox;

  MentionMeProvider() {
    _initTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    eventBox = EventMemBox();
  }

  void refresh() {
    _initTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    eventBox.clear();
    doQuery();

    mentionMeNewProvider.clear();
  }

  void deleteEvent(String id) {
    var result = eventBox.delete(id);
    if (result) {
      notifyListeners();
    }
  }

  int lastTime() {
    return _initTime;
  }

  ManySubscriptionHandle? subHandle;

  void doQuery({int? until}) {
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

    var relays = [...nostr.relayList.read];
    List<Filter> Function(String, List<Filter>)? filterModifier;

    if (!this.eventBox.isEmpty()) {
      var oldestCreatedAts = this.eventBox.oldestCreatedAtByRelay(relays);
      filterModifier = (url, filters) {
        filters[0].until = oldestCreatedAts.createdAtMap[url] ?? until;
        return filters;
      };
    }

    nostr.pool.querySync(relays, filter, filterModifier: filterModifier);
  }

  void onEvent(Event event) {
    later(event, (list) {
      var result = eventBox.addList(list);
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
    var allEvents = mentionMeNewProvider.eventMemBox.all();

    eventBox.addList(allEvents);
    eventBox.sort();
    mentionMeNewProvider.clear();

    // update ui
    notifyListeners();
  }
}
