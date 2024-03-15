import 'package:flutter/material.dart';

import 'package:nostrmo/client/event.dart';
import 'package:nostrmo/client/filter.dart';
import 'package:nostrmo/data/event_reactions.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/util/later_function.dart';
import 'package:nostrmo/util/when_stop_function.dart';

class EventReactionsProvider extends ChangeNotifier
    with LaterFunction, WhenStopFunction {
  int update_time = 1000 * 60 * 10;

  final Map<String, EventReactions> _eventReactionsMap = {};

  EventReactionsProvider() {
    laterTimeMS = 2000;
    whenStopMS = 500;
  }

  List<EventReactions> allReactions() {
    return _eventReactionsMap.values.toList();
  }

  void addRepost(String id) {
    var er = _eventReactionsMap[id];
    if (er != null) {
      er = er.clone();
      er.repostNum++;
      _eventReactionsMap[id] = er;
      notifyListeners();
    }
  }

  void addLike(String id, Event likeEvent) {
    var er = _eventReactionsMap[id];
    if (er != null) {
      er = er.clone();
      er.onEvent(likeEvent);
      _eventReactionsMap[id] = er;
      notifyListeners();
    }
  }

  void deleteLike(String id) {
    var er = _eventReactionsMap[id];
    if (er != null) {
      er = er.clone();
      if (er.myLikeEvents != null) {
        var length = er.myLikeEvents!.length;
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

  EventReactions? get(String id, {bool avoidPull = false}) {
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
      var now = DateTime.now();
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
    nostr.pool
        .querySync(nostr.relayList.read, Filter(e: _pendingIds.keys.toList()))
        .then((evts) => onEvents(evts.toList()));
  }

  void addEventAndHandle(Event event) {
    onEvent(event);
    laterFunc();
  }

  void onEvent(Event event) {
    _pendingEvents.add(event);
  }

  void onEvents(List<Event> events) {
    _pendingEvents.addAll(events);
  }

  final List<Event> _pendingEvents = [];

  void _handleEvent() {
    bool updated = false;

    for (var event in _pendingEvents) {
      for (var tag in event.tags) {
        if (tag.length > 1) {
          var tagType = tag[0];
          if (tagType == "e") {
            var id = tag[1];
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

  void removePending(String id) {
    _pendingIds.remove(id);
  }

  void clear() {
    _eventReactionsMap.clear();
  }
}
