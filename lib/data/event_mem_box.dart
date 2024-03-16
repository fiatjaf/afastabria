import "package:loure/client/event.dart";
import "package:loure/util/find_event_interface.dart";

/// a memory event box
/// use to hold event received from relay and offer event List to ui
class EventMemBox implements FindEventInterface {
  EventMemBox({this.sortAfterAdd = true});
  final List<Event> _eventList = [];
  final Map<String, Event> _idMap = {};
  bool sortAfterAdd;

  @override
  List<Event> findEvent(final String str, {final int? limit = 5}) {
    List<Event> list = [];
    for (final event in _eventList) {
      if (event.content.contains(str)) {
        list.add(event);

        if (limit != null && list.length >= limit) {
          break;
        }
      }
    }
    return list;
  }

  Event? get newestEvent {
    if (_eventList.isEmpty) {
      return null;
    }
    return _eventList.first;
  }

  Event? get oldestEvent {
    if (_eventList.isEmpty) {
      return null;
    }
    return _eventList.last;
  }

  // find event oldest createdAt by relay
  OldestCreatedAtByRelayResult oldestCreatedAtByRelay(
      final List<String> relayURLs,
      [final int? initTime]) {
    final OldestCreatedAtByRelayResult result = OldestCreatedAtByRelayResult();

    final length = _eventList.length;
    for (var index = length - 1; index > -1; index--) {
      final event = _eventList[index];
      for (final source in event.sources) {
        final idx = relayURLs.indexOf(source);
        if (idx != -1) {
          // log("$source findCreatedAt $length $index ${length - index}");
          result.createdAtMap[source] = event.createdAt;
          relayURLs.removeAt(idx);
        }
      }

      if (relayURLs.length == 0) {
        break;
      }
    }

    if (relayURLs.length > 0 && initTime != null) {
      for (final url in relayURLs) {
        result.createdAtMap[url] = initTime;
      }
    }

    // count av createdAt
    final it = result.createdAtMap.values;
    final relayNum = it.length;
    double counter = 0;
    for (final value in it) {
      counter += value;
    }
    result.avCreatedAt = counter ~/ relayNum;

    return result;
  }

  void sort() {
    _eventList.sort((final event1, final event2) {
      return event2.createdAt - event1.createdAt;
    });
  }

  bool delete(final String id) {
    if (_idMap[id] == null) {
      return false;
    }

    _idMap.remove(id);
    _eventList.removeWhere((final element) => element.id == id);

    return true;
  }

  bool add(final Event event) {
    final oldEvent = _idMap[event.id];
    if (oldEvent != null) {
      if (event.sources.isNotEmpty &&
          !oldEvent.sources.contains(event.sources.first)) {
        oldEvent.sources.add(event.sources.first);
      }
      return false;
    }

    _idMap[event.id] = event;
    _eventList.add(event);
    if (sortAfterAdd) {
      sort();
    }
    return true;
  }

  bool addList(final List<Event> list) {
    bool added = false;
    for (final event in list) {
      final oldEvent = _idMap[event.id];
      if (oldEvent == null) {
        _idMap[event.id] = event;
        _eventList.add(event);
        added = true;
      } else {
        if (event.sources.isNotEmpty &&
            !oldEvent.sources.contains(event.sources.first)) {
          oldEvent.sources.add(event.sources.first);
        }
      }
    }

    if (added && sortAfterAdd) {
      sort();
    }

    return added;
  }

  void addBox(final EventMemBox b) {
    final all = b.all();
    addList(all);
  }

  bool isEmpty() {
    return _eventList.isEmpty;
  }

  int length() {
    return _eventList.length;
  }

  List<Event> all() {
    return _eventList;
  }

  List<Event> listByPubkey(final String pubkey) {
    List<Event> list = [];
    for (final event in _eventList) {
      if (event.pubKey == pubkey) {
        list.add(event);
      }
    }
    return list;
  }

  List<Event> suList(final int start, final int limit) {
    final length = _eventList.length;
    if (start > length) {
      return [];
    }
    if (start + limit > length) {
      return _eventList.sublist(start, length);
    }
    return _eventList.sublist(start, limit);
  }

  Event? get(final int index) {
    if (_eventList.length < index) {
      return null;
    }

    return _eventList[index];
  }

  void clear() {
    _eventList.clear();
    _idMap.clear();
  }
}

class OldestCreatedAtByRelayResult {
  Map<String, int> createdAtMap = {};

  int avCreatedAt = 0;
}
