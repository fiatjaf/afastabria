import 'dart:convert';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:nostrmo/client/aid.dart';
import 'package:nostrmo/client/event.dart';
import 'package:nostrmo/client/filter.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/util/string_util.dart';

import 'package:nostrmo/client/event_kind.dart';
import 'package:nostrmo/client/nip04/nip04.dart';
import 'package:nostrmo/client/nip51/bookmarks.dart';
import 'package:nostrmo/data/custom_emoji.dart';

/// Standard list provider.
/// These list usually publish by user himself and the provider will hold the newest one.
abstract class ListProvider extends ChangeNotifier {
  final int kind;

  ListProvider(this.kind);

  Event? latest;

  void init() {
    nostr.pool.subscribeMany(nostr.relayList.write, [
      Filter(
        kinds: [this.kind],
        authors: [nostr.publicKey],
      )
    ], onEvent: (Event evt) {
      if (this.latest == null || evt.createdAt > this.latest!.createdAt) {
        this.latest = evt;
        this.processEvent();
        this.notifyListeners();
      }
    });
  }

  void processEvent();

  void clear() {
    latest = null;
  }
}

class BookmarkProvider extends ListProvider {
  BookmarkProvider() : super(EventKind.BOOKMARKS_LIST);

  Bookmarks bookmarks = Bookmarks();

  @override
  processEvent() {
    if (this.latest != null) {
      this.parseBookmarks(this.latest!);
    }
  }

  void parseBookmarks(Event evt) {
    var bookmarks = Bookmarks();
    var content = evt.content;
    if (StringUtil.isNotBlank(content)) {
      var agreement = NIP04.getAgreement(nostr.privateKey);
      var plainContent = NIP04.decrypt(content, agreement, nostr.publicKey);

      var jsonObj = jsonDecode(plainContent);
      if (jsonObj is List) {
        List<BookmarkItem> privateItems = [];
        for (var jsonObjItem in jsonObj) {
          if (jsonObjItem is List && jsonObjItem.length > 1) {
            var key = jsonObjItem[0];
            var value = jsonObjItem[1];
            if (key is String && value is String) {
              privateItems.add(BookmarkItem(key: key, value: value));
            }
          }
        }

        bookmarks.privateItems = privateItems;
      }
    }

    List<BookmarkItem> publicItems = [];
    for (var jsonObjItem in evt.tags) {
      if (jsonObjItem.length > 1) {
        var key = jsonObjItem[0];
        var value = jsonObjItem[1];
        publicItems.add(BookmarkItem(key: key, value: value));
      }
    }
    bookmarks.publicItems = publicItems;
    this.bookmarks = bookmarks;
  }

  void addPrivateBookmark(BookmarkItem bookmarkItem) {
    this.bookmarks.privateItems.add(bookmarkItem);
    saveBookmarks();
  }

  void addPublicBookmark(BookmarkItem bookmarkItem) {
    this.bookmarks.publicItems.add(bookmarkItem);
    saveBookmarks();
  }

  void removePrivateBookmark(String value) {
    this.bookmarks.privateItems.removeWhere((items) {
      return items.value == value;
    });
    saveBookmarks();
  }

  void removePublicBookmark(String value) {
    this.bookmarks.publicItems.removeWhere((items) {
      return items.value == value;
    });
    saveBookmarks();
  }

  void saveBookmarks() {
    var content = "";
    if (this.bookmarks.privateItems.isNotEmpty) {
      List<List> list = [];
      for (var item in this.bookmarks.privateItems) {
        list.add(item.toJson());
      }

      var agreement = NIP04.getAgreement(nostr.privateKey);
      var jsonText = jsonEncode(list);
      content = NIP04.encrypt(jsonText, agreement, nostr.publicKey);
    }

    List<List<String>> tags = [];
    for (var item in this.bookmarks.publicItems) {
      tags.add(item.toJson());
    }

    var resultEvent = nostr.sendList(EventKind.BOOKMARKS_LIST, tags, content);
    this.latest = resultEvent;

    notifyListeners();
  }

  bool checkPublicBookmark(BookmarkItem item) {
    for (var bi in bookmarks.publicItems) {
      if (bi.value == item.value) {
        return true;
      }
    }

    return false;
  }

  bool checkPrivateBookmark(BookmarkItem item) {
    for (var bi in bookmarks.privateItems) {
      if (bi.value == item.value) {
        return true;
      }
    }

    return false;
  }
}

class EmojiProvider extends ListProvider {
  EmojiProvider() : super(EventKind.EMOJIS_LIST);

  Bookmarks bookmarks = Bookmarks();

  @override
  processEvent() {}

  List<MapEntry<String, List<CustomEmoji>>> emojis(Event? emojiEvent) {
    List<MapEntry<String, List<CustomEmoji>>> result = [];

    List<CustomEmoji> list = [];

    if (emojiEvent != null) {
      for (var tag in emojiEvent.tags) {
        if (tag.isNotEmpty) {
          var tagKey = tag[0];
          if (tagKey == "emoji" && tag.length > 2) {
            // emoji config config inside.
            var k = tag[1];
            var v = tag[2];
            list.add(CustomEmoji(k, v));
          } else if (tagKey == "a" && tag.length > 1) {
            // emoji config by other listSet
            var aIdStr = tag[1];
            var listSetEvent = listSetProvider.getByAId(aIdStr);
            if (listSetEvent != null) {
              // find the listSet
              var aId = AId.fromString(aIdStr);
              String title = "unknow";
              if (aId != null) {
                title = aId.title;
              }

              List<CustomEmoji> subList = [];
              for (var tag in listSetEvent.tags) {
                if (tag.length > 2) {
                  var tagKey = tag[0];
                  var k = tag[1];
                  var v = tag[2];
                  if (tagKey == "emoji") {
                    subList.add(CustomEmoji(k, v));
                  }
                }
              }

              result.add(MapEntry(title, subList));
            }
          }
        }
      }
    }
    result.insert(0, MapEntry("Custom", list));

    return result;
  }

  void addCustomEmoji(CustomEmoji emoji) {
    var cancelFunc = BotToast.showLoading();

    try {
      List<List<String>> tags = [];

      var emojiEvent = this.latest;
      if (emojiEvent != null) {
        tags.addAll(emojiEvent.tags);
      }
      tags.add(["emoji", emoji.name, emoji.filepath]);
      this.latest = nostr.sendList(EventKind.EMOJIS_LIST, tags, "");
      notifyListeners();
    } finally {
      cancelFunc.call();
    }
  }
}
