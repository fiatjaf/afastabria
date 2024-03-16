import "package:loure/client/event.dart";

class ContentEventTagInfos {
  ContentEventTagInfos.fromEvent(final Event event) {
    for (final tag in event.tags) {
      if (tag.length > 1) {
        final key = tag[0];
        final value = tag[1];
        if (key == "emoji" && tag.length > 2) {
          // emojiMap[":${tag[1]}:"] = tag[2];
          emojiMap[tag[1]] = tag[2];
        } else if (key == "t") {
          tagMap[value] = value.length;
        }
      }
    }

    if (tagMap.isNotEmpty) {
      tagEntryInfos = tagMap.entries.toList();
      tagEntryInfos.sort((final entry0, final entry1) {
        return entry1.value - entry0.value;
      });
    }
  }
  Map<String, String> emojiMap = {};
  Map<String, int> tagMap = {};
  List<MapEntry<String, int>> tagEntryInfos = [];
}
