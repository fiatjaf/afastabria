import "package:loure/client/event.dart";

class LongFormInfo {
  LongFormInfo.fromEvent(final Event event) {
    final length = event.tags.length;
    for (var i = 0; i < length; i++) {
      final tag = event.tags[i];
      final tagLength = tag.length;
      if (tagLength > 1) {
        final value = tag[1];
        if (tag[0] == "title") {
          title = value;
        } else if (tag[0] == "summary") {
          summary = value;
        } else if (tag[0] == "published_at") {
          publishedAt = int.tryParse(value);
        } else if (tag[0] == "t") {
          topics.add(value);
        } else if (tag[0] == "image") {
          image = value;
        } else if (tag[0] == "a") {
          as.add(value);
        }
      }
    }
  }
  String? title;

  String? image;

  String? summary;

  int? publishedAt;

  List<String> topics = [];

  List<String> as = [];
}
