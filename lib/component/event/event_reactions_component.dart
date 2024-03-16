import "dart:convert";

import "package:bot_toast/bot_toast.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_quill/flutter_quill.dart" as quill;
import "package:loure/client/nip51/bookmarks.dart";
import "package:loure/component/enum_selector_component.dart";
import "package:loure/component/zap_gen_dialog.dart";
import "package:provider/provider.dart";
import "package:screenshot/screenshot.dart";
import "package:share_plus/share_plus.dart";

import "package:loure/client/event.dart";
import "package:loure/client/event_relation.dart";
import "package:loure/client/nip19/nip19.dart";
import "package:loure/client/zap/zap_action.dart";
import "package:loure/consts/base_consts.dart";
import "package:loure/consts/router_path.dart";
import "package:loure/data/event_reactions.dart";
import "package:loure/main.dart";
import "package:loure/provider/event_reactions_provider.dart";
import "package:loure/router/edit/editor_router.dart";
import "package:loure/util/number_format_util.dart";
import "package:loure/util/router_util.dart";
import "package:loure/util/store_util.dart";
import "package:loure/util/string_util.dart";
import "package:loure/component/editor/cust_embed_types.dart";
import "package:loure/component/event_delete_callback.dart";
import "package:loure/component/event_reply_callback.dart";

// ignore: must_be_immutable
class EventReactionsComponent extends StatefulWidget {
  EventReactionsComponent({
    required this.screenshotController,
    required this.event,
    required this.eventRelation,
    super.key,
    this.showDetailBtn = true,
  });
  ScreenshotController screenshotController;

  Event event;

  EventRelation eventRelation;

  bool showDetailBtn;

  @override
  State<StatefulWidget> createState() {
    return _EventReactionsComponent();
  }
}

class _EventReactionsComponent extends State<EventReactionsComponent> {
  List<Event>? myLikeEvents;

  @override
  Widget build(final BuildContext context) {
    final themeData = Theme.of(context);
    final hintColor = themeData.hintColor;
    final fontSize = themeData.textTheme.bodySmall!.fontSize!;
    final mediumFontSize = themeData.textTheme.bodyMedium!.fontSize;
    final popFontStyle = TextStyle(
      fontSize: mediumFontSize,
    );

    return Selector<EventReactionsProvider, EventReactions?>(
      builder: (final context, final eventReactions, final child) {
        int replyNum = 0;
        int repostNum = 0;
        int likeNum = 0;
        int zapNum = 0;
        Color likeColor = hintColor;

        if (eventReactions != null) {
          replyNum = eventReactions.replies.length;
          repostNum = eventReactions.repostNum;
          likeNum = eventReactions.likeNum;
          zapNum = eventReactions.zapNum;

          myLikeEvents = eventReactions.myLikeEvents;
        }
        if (myLikeEvents != null && myLikeEvents!.isNotEmpty) {
          likeColor = Colors.red;
        }

        return SizedBox(
          height: 34,
          child: Row(
            children: [
              Expanded(
                  child: EventReactionNumComponent(
                num: replyNum,
                iconData: Icons.comment,
                onTap: onCommmentTap,
                color: hintColor,
                fontSize: fontSize,
              )),
              // Expanded(
              //     child: EventReactionNumComponent(
              //   num: repostNum,
              //   iconData: Icons.repeat,
              //   onTap: onRepostTap,
              //   color: hintColor,
              //   fontSize: fontSize,
              // )),
              Expanded(
                child: PopupMenuButton<String>(
                  tooltip: "Boost",
                  itemBuilder: (final context) {
                    return [
                      const PopupMenuItem(
                        value: "boost",
                        child: Text("Boost"),
                      ),
                      const PopupMenuItem(
                        value: "quote",
                        child: Text("Quote"),
                      ),
                    ];
                  },
                  onSelected: onRepostTap,
                  child: EventReactionNumComponent(
                    num: repostNum,
                    iconData: Icons.repeat,
                    color: hintColor,
                    fontSize: fontSize,
                  ),
                ),
              ),
              Expanded(
                  child: EventReactionNumComponent(
                num: likeNum,
                iconData: Icons.favorite,
                onTap: onLikeTap,
                color: likeColor,
                fontSize: fontSize,
              )),
              Expanded(
                child: PopupMenuButton<int>(
                  tooltip: "Zap",
                  itemBuilder: (final context) {
                    return [
                      PopupMenuItem(
                        value: 10,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.bolt, color: Colors.orange),
                            Text(" Zap 10", style: popFontStyle)
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 50,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.bolt, color: Colors.orange),
                            Text(" Zap 50", style: popFontStyle)
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 100,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.bolt, color: Colors.orange),
                            Text(" Zap 100", style: popFontStyle)
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 500,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.bolt, color: Colors.orange),
                            Text(" Zap 500", style: popFontStyle)
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 1000,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.bolt, color: Colors.orange),
                            Text(" Zap 1000", style: popFontStyle)
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 5000,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.bolt, color: Colors.orange),
                            Text(" Zap 5000", style: popFontStyle)
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: -1,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.bolt, color: Colors.orange),
                            Text(" ${"Custom"}", style: popFontStyle)
                          ],
                        ),
                      ),
                    ];
                  },
                  onSelected: onZapSelect,
                  child: EventReactionNumComponent(
                    num: zapNum,
                    iconData: Icons.bolt,
                    onTap: null,
                    onLongPress: genZap,
                    color: hintColor,
                    fontSize: fontSize,
                  ),
                ),
              ),
              Expanded(
                child: PopupMenuButton<String>(
                  tooltip: "More",
                  itemBuilder: (final context) {
                    final bookmarkItem = BookmarkItem.getFromEventReactions(
                        widget.eventRelation);

                    List<PopupMenuEntry<String>> list = [
                      PopupMenuItem(
                        value: "copyEvent",
                        child: Text("Copy Note Json", style: popFontStyle),
                      ),
                      PopupMenuItem(
                        value: "copyPubkey",
                        child: Text("Copy Note Pubkey", style: popFontStyle),
                      ),
                      PopupMenuItem(
                        value: "copyId",
                        child: Text("Copy Note Id", style: popFontStyle),
                      ),
                      const PopupMenuDivider(),
                    ];

                    if (widget.showDetailBtn) {
                      list.add(PopupMenuItem(
                        value: "detail",
                        child: Text("Detail", style: popFontStyle),
                      ));
                    }

                    list.add(PopupMenuItem(
                      value: "share",
                      child: Text("Share", style: popFontStyle),
                    ));
                    list.add(const PopupMenuDivider());
                    if (bookmarkProvider.checkPrivateBookmark(bookmarkItem)) {
                      list.add(PopupMenuItem(
                        value: "removeFromPrivateBookmark",
                        child: Text("Remove from private bookmark",
                            style: popFontStyle),
                      ));
                    } else {
                      list.add(PopupMenuItem(
                        value: "addToPrivateBookmark",
                        child: Text("Add to private bookmark",
                            style: popFontStyle),
                      ));
                    }
                    if (bookmarkProvider.checkPublicBookmark(bookmarkItem)) {
                      list.add(PopupMenuItem(
                        value: "removeFromPublicBookmark",
                        child: Text("Remove from public bookmark",
                            style: popFontStyle),
                      ));
                    } else {
                      list.add(PopupMenuItem(
                        value: "addToPublicBookmark",
                        child:
                            Text("Add to public bookmark", style: popFontStyle),
                      ));
                    }
                    list.add(const PopupMenuDivider());
                    list.add(PopupMenuItem(
                      value: "source",
                      child: Text("Source", style: popFontStyle),
                    ));
                    list.add(PopupMenuItem(
                      value: "broadcase",
                      child: Text("Broadcast", style: popFontStyle),
                    ));
                    list.add(PopupMenuItem(
                      value: "block",
                      child: Text("Block", style: popFontStyle),
                    ));

                    if (widget.event.pubKey == nostr.publicKey) {
                      list.add(const PopupMenuDivider());
                      list.add(PopupMenuItem(
                        value: "delete",
                        child: Text(
                          "Delete",
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: mediumFontSize,
                          ),
                        ),
                      ));
                    }

                    return list;
                  },
                  onSelected: onPopupSelected,
                  child: Icon(
                    Icons.more_vert,
                    size: 16,
                    color: hintColor,
                  ),
                ),
              ),
            ],
          ),
        );
      },
      selector: (final context, final provider) {
        return provider.get(widget.event.id);
      },
      shouldRebuild: (final previous, final next) {
        if ((previous == null && next != null) ||
            (previous != null &&
                next != null &&
                (previous.replies.length != next.replies.length ||
                    previous.repostNum != next.repostNum ||
                    previous.likeNum != next.likeNum ||
                    previous.zapNum != next.zapNum))) {
          return true;
        }

        return false;
      },
    );
  }

  void onPopupSelected(final String value) {
    if (value == "copyEvent") {
      final text = jsonEncode(widget.event.toJson());
      _doCopy(text);
    } else if (value == "copyPubkey") {
      final text = Nip19.encodePubKey(widget.event.pubKey);
      _doCopy(text);
    } else if (value == "copyId") {
      final text = Nip19.encodeNoteId(widget.event.id);
      _doCopy(text);
    } else if (value == "detail") {
      RouterUtil.router(context, RouterPath.EVENT_DETAIL, widget.event);
    } else if (value == "share") {
      onShareTap();
    } else if (value == "addToPrivateBookmark") {
      final item = BookmarkItem.getFromEventReactions(widget.eventRelation);
      bookmarkProvider.addPrivateBookmark(item);
    } else if (value == "addToPublicBookmark") {
      final item = BookmarkItem.getFromEventReactions(widget.eventRelation);
      bookmarkProvider.addPublicBookmark(item);
    } else if (value == "removeFromPrivateBookmark") {
      final item = BookmarkItem.getFromEventReactions(widget.eventRelation);
      bookmarkProvider.removePrivateBookmark(item.value);
    } else if (value == "removeFromPublicBookmark") {
      final item = BookmarkItem.getFromEventReactions(widget.eventRelation);
      bookmarkProvider.removePublicBookmark(item.value);
    } else if (value == "broadcast") {
      bookmarkProvider.saveBookmarks();
    } else if (value == "source") {
      List<EnumObj> list = [];
      for (final source in widget.event.sources) {
        list.add(EnumObj(source, source));
      }
      EnumSelectorComponent.show(context, list);
    } else if (value == "block") {
      filterProvider.addBlock(widget.event.pubKey);
    } else if (value == "delete") {
      nostr.deleteEvent(widget.event.id);
      followEventProvider.deleteEvent(widget.event.id);
      mentionMeProvider.deleteEvent(widget.event.id);
      final deleteCallback = EventDeleteCallback.of(context);
      if (deleteCallback != null) {
        deleteCallback.onDelete(widget.event);
      }
      // BotToast.showText(text: "Delete success!");
    }
  }

  void _doCopy(final String text) {
    Clipboard.setData(ClipboardData(text: text)).then((final _) {
      BotToast.showText(text: "Copy success");
    });
  }

  @override
  void dispose() {
    super.dispose();
    final id = widget.event.id;
    eventReactionsProvider.removePending(id);
  }

  Future<void> onCommmentTap() async {
    final er = widget.eventRelation;
    List<List<String>> tags = [];
    List<List<String>> tagsAddedWhenSend = [];
    String relayAddr = "";
    if (widget.event.sources.isNotEmpty) {
      relayAddr = widget.event.sources.first;
    }
    String directMarked = "reply";
    if (StringUtil.isBlank(er.rootId)) {
      directMarked = "root";
    }
    tagsAddedWhenSend.add(["e", widget.event.id, relayAddr, directMarked]);

    List<List<String>> tagPs = [];
    tagPs.add(["p", widget.event.pubKey]);
    if (er.tagPList.isNotEmpty) {
      for (final p in er.tagPList) {
        tagPs.add(["p", p]);
      }
    }
    if (StringUtil.isNotBlank(er.rootId)) {
      String relayAddr = "";
      if (StringUtil.isNotBlank(er.rootRelayAddr)) {
        relayAddr = er.rootRelayAddr!;
      }
      tags.add(["e", er.rootId ?? "", relayAddr, "root"]);
    }

    final event = await EditorRouter.open(context,
        tags: tags, tagsAddedWhenSend: tagsAddedWhenSend, tagPs: tagPs);
    if (event != null) {
      eventReactionsProvider.addEventAndHandle(event);
      final callback = EventReplyCallback.of(context);
      if (callback != null) {
        callback.onReply(event);
      }
    }
  }

  Future<void> onRepostTap(final String value) async {
    if (value == "boost") {
      nostr.sendRepost(widget.event.id);
      eventReactionsProvider.addRepost(widget.event.id);
    } else if (value == "quote") {
      final event = await EditorRouter.open(context, initEmbeds: [
        quill.CustomBlockEmbed(CustEmbedTypes.mention_event, widget.event.id)
      ]);
      print(event);
    }
  }

  void onLikeTap() {
    if (myLikeEvents == null || myLikeEvents!.isEmpty) {
      // like
      final likeEvent = nostr.sendLike(widget.event.id);
      if (likeEvent != null) {
        eventReactionsProvider.addLike(widget.event.id, likeEvent);
      }
    } else {
      // delete like
      for (final event in myLikeEvents!) {
        nostr.deleteEvent(event.id);
      }
      eventReactionsProvider.deleteLike(widget.event.id);
    }
  }

  Future<void> onZapSelect(final int sats) async {
    if (sats < 0) {
      genZap();
    } else {
      await ZapAction.handleZap(context, sats, widget.event.pubKey,
          eventId: widget.event.id);
    }
  }

  void onShareTap() {
    widget.screenshotController
        .capture()
        .then((final Uint8List? imageData) async {
      if (imageData != null) {
        final tempFile = await StoreUtil.saveBS2TempFile(
          "png",
          imageData,
        );
        Share.shareXFiles([XFile(tempFile)]);
      }
    }).catchError(print);
  }

  void genZap() {
    ZapGenDialog.show(context, widget.event.pubKey, eventId: widget.event.id);
  }
}

// ignore: must_be_immutable
class EventReactionNumComponent extends StatelessWidget {
  EventReactionNumComponent({
    required this.iconData,
    required this.num,
    required this.color,
    required this.fontSize,
    super.key,
    this.onTap,
    this.onLongPress,
  });
  IconData iconData;

  int num;

  GestureTapCallback? onTap;

  GestureLongPressCallback? onLongPress;

  Color color;

  double fontSize;

  @override
  Widget build(final BuildContext context) {
    Widget? main;
    final iconWidget = Icon(
      iconData,
      size: 14,
      color: color,
    );
    if (num != 0) {
      final String numStr = NumberFormatUtil.format(num);

      main = Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          iconWidget,
          Container(
            margin: const EdgeInsets.only(left: 4),
            child: Text(
              numStr,
              style: TextStyle(color: color, fontSize: fontSize),
            ),
          ),
        ],
      );
    } else {
      main = iconWidget;
    }

    if (onTap != null || onLongPress != null) {
      return GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          alignment: Alignment.center,
          child: main,
        ),
      );
    } else {
      return Container(
        alignment: Alignment.center,
        child: main,
      );
    }
  }
}
