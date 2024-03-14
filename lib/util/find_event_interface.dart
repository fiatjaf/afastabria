import 'package:nostrmo/client/event.dart';

abstract class FindEventInterface {
  List<Event> findEvent(String str, {int? limit = 5});
}
