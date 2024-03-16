import "package:loure/client/event.dart";

abstract class FindEventInterface {
  List<Event> findEvent(final String str, {final int? limit = 5});
}
