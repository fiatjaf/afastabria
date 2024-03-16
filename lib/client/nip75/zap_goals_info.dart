import "package:loure/client/event.dart";

class ZapGoalsInfo {
  ZapGoalsInfo.fromEvent(final Event event) {
    final length = event.tags.length;
    for (var i = 0; i < length; i++) {
      final tag = event.tags[i];
      final tagLength = tag.length;
      if (tagLength > 1) {
        final key = tag[0];
        final value = tag[1];
        if (key == "amount") {
          amount = int.tryParse(value);
          if (amount != null) {
            amount = amount! ~/ 1000;
          }
        } else if (key == "zapraiser") {
          amount = int.tryParse(value);
        } else if (key == "closed_at") {
          closedAt = int.tryParse(value);
        } else if (key == "relays") {
          relays = tag.sublist(1);
        } else if (key == "r") {
          r = value;
        } else if (key == "a") {
          a = value;
        } else if (key == "goal") {
          goal = value;
          if (tag.length > 1) {
            goalRelay = tag[2];
          }
        }
      }
    }
  }
  int? amount;

  List<String>? relays;

  int? closedAt;

  String? r;

  String? a;

  String? goal;

  String? goalRelay;
}
