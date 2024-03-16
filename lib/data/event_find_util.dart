import "package:loure/main.dart";

import "package:loure/client/event.dart";
import "package:loure/util/find_event_interface.dart";
import "package:loure/data/event_mem_box.dart";

class EventFindUtil {
  static List<Event> findEvent(final String str, {final int? limit = 5}) {
    List<FindEventInterface> finders = [followEventProvider];
    finders.addAll(eventReactionsProvider.allReactions());

    final eventBox = EventMemBox(sortAfterAdd: false);
    for (final finder in finders) {
      final list = finder.findEvent(str, limit: limit);
      if (list.isNotEmpty) {
        eventBox.addList(list);

        if (limit != null && eventBox.length() >= limit) {
          break;
        }
      }
    }
    eventBox.sort();
    return eventBox.all();
  }
}
