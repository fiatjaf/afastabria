import "package:loure/data/event_mem_box.dart";
import "package:loure/client/event.dart";

class DMSession {
  DMSession({required this.pubkey});
  final String pubkey;

  EventMemBox _box = EventMemBox();

  DMSession clone() {
    return DMSession(pubkey: pubkey).._box = _box;
  }

  bool addEvent(final Event event) {
    return _box.add(event);
  }

  void addEvents(final List<Event> events) {
    _box.addList(events);
  }

  Event? get newestEvent {
    return _box.newestEvent;
  }

  int length() {
    return _box.length();
  }

  Event? get(final int index) {
    if (_box.length() <= index) {
      return null;
    }

    return _box.get(index);
  }

  int lastTime() {
    return _box.newestEvent!.createdAt;
  }
}
