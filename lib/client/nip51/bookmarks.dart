import "package:loure/client/event_relation.dart";

class Bookmarks {
  List<BookmarkItem> privateItems = [];
  List<BookmarkItem> publicItems = [];
}

class BookmarkItem {
  BookmarkItem({
    required this.key,
    required this.value,
  });
  String key;
  String value;

  List<String> toJson() {
    List<String> list = [];
    list.add(key);
    list.add(value);
    return list;
  }

  static BookmarkItem getFromEventReactions(final EventRelation eventRelation) {
    var key = "e";
    var value = eventRelation.id;
    final aId = eventRelation.aId;
    if (aId != null) {
      key = "a";
      value = aId.toTag();
    }
    return BookmarkItem(key: key, value: value);
  }
}
