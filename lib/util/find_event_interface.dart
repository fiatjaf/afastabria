import 'package:loure/client/event.dart';

abstract class FindEventInterface {
  List<Event> findEvent(String str, {int? limit = 5});
}
