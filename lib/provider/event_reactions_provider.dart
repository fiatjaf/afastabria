import "package:flutter/material.dart";

import "package:loure/client/event.dart";
import "package:loure/client/filter.dart";
import "package:loure/data/event_reactions.dart";
import "package:loure/main.dart";
import "package:loure/util/later_function.dart";
import "package:loure/util/when_stop_function.dart";

class EventReactionsProvider extends ChangeNotifier
    with LaterFunction, WhenStopFunction {
  EventReactionsProvider() {
    laterTimeMS = 2000;
    whenStopMS = 500;
  }
  int update_time = 1000 * 60 * 10;

  final Map<String, EventReactions> _eventReactionsMap = {};

  List<EventReactions> allReactions() {
    return _eventReactionsMap.values.toList();
  }

  void addRepost(final String id) {
    var er = _eventReactionsMap[id];
    if (er != null) {
      er = er.clone();
      er.repostNum++;
      _eventReactionsMap[id] = er;
      notifyListeners();
    }
  }

  void addLike(final String id, final Event likeEvent) {
    var er = _eventReactionsMap[id];
    if (er != null) {
      er = er.clone();
      er.onEvent(likeEvent);
      _eventReactionsMap[id] = er;
      notifyListeners();
    }
  }

  void deleteLike(final String id) {
    var er = _eventReactionsMap[id];
    if (er != null) {
      er = er.clone();
      if (er.myLikeEvents != null) {
        final length = er.myLikeEvents!.length;
        er.likeNum -= length;
      } else {
        er.likeNum--;
      }
      er.myLikeEvents = null;
      _eventReactionsMap[id] = er;
      notifyListeners();
    }
  }

  // void update(String id) {
  //   _pendingIds[id] = 1;
  //   whenStop(laterFunc);
  // }

  EventReactions? get(final String id, {final bool avoidPull = false}) {
    var er = _eventReactionsMap[id];
    if (er == null) {
      if (avoidPull) {
        return null;
      }

      // plan to pull
      _pendingIds[id] = 1;
      // later(laterFunc, null);
      whenStop(laterFunc);
      // set a empty er to avoid pull many times
      er = EventReactions(id);
      _eventReactionsMap[id] = er;
    } else {
      final now = DateTime.now();
      // check dataTime if need to update
      if (now.millisecondsSinceEpoch - er.dataTime.millisecondsSinceEpoch >
          update_time) {
        _pendingIds[id] = 1;
        // later(laterFunc, null);
        whenStop(laterFunc);
      }
      // set the access time, remove cache base on this time.
      er.access(now);
    }
    return er;
  }

  void laterFunc() {
    if (_pendingIds.isNotEmpty) {
      _doPull();
    }
    if (_pendingEvents.isNotEmpty) {
      _handleEvent();
    }
  }

  final Map<String, int> _pendingIds = {};

  void _doPull() {
    if (_pendingIds.isEmpty) {
      return;
    }

    _pendingIds.clear();
    pool
        .querySync(nostr.relayList.read, Filter(e: _pendingIds.keys.toList()))
        .then((final evts) => onEvents(evts.toList()));
  }

  void addEventAndHandle(final Event event) {
    onEvent(event);
    laterFunc();
  }

  void onEvent(final Event event) {
    _pendingEvents.add(event);
  }

  void onEvents(final List<Event> events) {
    _pendingEvents.addAll(events);
  }

  final List<Event> _pendingEvents = [];

  void _handleEvent() {
    bool updated = false;

    for (final event in _pendingEvents) {
      for (final tag in event.tags) {
        if (tag.length > 1) {
          final tagType = tag[0];
          if (tagType == "e") {
            final id = tag[1];
            var er = _eventReactionsMap[id];
            if (er == null) {
              er = EventReactions(id);
              _eventReactionsMap[id] = er;
            } else {
              er = er.clone();
              _eventReactionsMap[id] = er;
            }

            if (er.onEvent(event)) {
              updated = true;
            }
          }
        }
      }
    }
    _pendingEvents.clear();

    if (updated) {
      notifyListeners();
    }
  }

  void removePending(final String id) {
    _pendingIds.remove(id);
  }

  void clear() {
    _eventReactionsMap.clear();
  }
}
