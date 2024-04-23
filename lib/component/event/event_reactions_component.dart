import "dart:convert";

import "package:bot_toast/bot_toast.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_quill/flutter_quill.dart" as quill;
import "package:loure/client/event_kind.dart";
import "package:loure/client/input.dart";
import "package:loure/component/editor.dart";
import "package:provider/provider.dart";
import "package:screenshot/screenshot.dart";
import "package:share_plus/share_plus.dart";
import "package:url_launcher/url_launcher.dart";

import "package:loure/client/nip51/bookmarks.dart";
import "package:loure/component/enum_selector_component.dart";
import "package:loure/util/platform_util.dart";
import "package:loure/client/event.dart";
import "package:loure/client/event_relation.dart";
import "package:loure/client/nip19/nip19.dart";
import "package:loure/consts/base_consts.dart";
import "package:loure/data/event_reactions.dart";
import "package:loure/main.dart";
import "package:loure/provider/event_reactions_provider.dart";
import "package:loure/router/edit/editor_router.dart";
import "package:loure/util/number_format_util.dart";
import "package:loure/util/store_util.dart";
import "package:loure/component/editor/cust_embed_types.dart";

class EventReactionsComponent extends StatefulWidget {
  const EventReactionsComponent({
    required this.screenshotController,
    required this.event,
    required this.eventRelation,
    super.key,
  });

  final ScreenshotController screenshotController;
  final Event event;
  final EventRelation eventRelation;

  @override
  State<StatefulWidget> createState() {
    return _EventReactionsComponent();
  }
}

class _EventReactionsComponent extends State<EventReactionsComponent> {
  List<Event>? myLikeEvents;
  bool commenting = false;

  @override
  Widget build(final BuildContext context) {
    final themeData = Theme.of(context);
    final hintColor = themeData.hintColor;
    final fontSize = themeData.textTheme.bodySmall!.fontSize!;
    final mediumFontSize = themeData.textTheme.bodyMedium!.fontSize;
    final popFontStyle = TextStyle(
      fontSize: mediumFontSize,
    );

    return Column(
      children: [
        Selector<EventReactionsProvider, EventReactions?>(
          builder: (final context, final eventReactions, final child) {
            int replyNum = 0;
            int repostNum = 0;
            int likeNum = 0;
            Color likeColor = hintColor;

            if (eventReactions != null) {
              replyNum = eventReactions.replies.length;
              repostNum = eventReactions.repostNum;
              likeNum = eventReactions.likeNum;

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
                    child: Tooltip(
                      message: "Reply",
                      child: EventReactionNumComponent(
                        num: replyNum,
                        iconData: Icons.comment,
                        onTap: onCommmentTap,
                        color: hintColor,
                        fontSize: fontSize,
                      ),
                    ),
                  ),
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
                    child: Tooltip(
                      message: "Like",
                      child: EventReactionNumComponent(
                        num: likeNum,
                        iconData: Icons.favorite,
                        onTap: onLikeTap,
                        color: likeColor,
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
                            child: Text("Copy raw JSON", style: popFontStyle),
                          ),
                          PopupMenuItem(
                            value: "copyPubkey",
                            child:
                                Text("Copy author npub", style: popFontStyle),
                          ),
                          PopupMenuItem(
                            value: "copyId",
                            child: Text("Copy event id", style: popFontStyle),
                          ),
                          const PopupMenuDivider(),
                        ];

                        list.add(PopupMenuItem(
                          value: "share",
                          child: Text("Share", style: popFontStyle),
                        ));
                        list.add(const PopupMenuDivider());
                        if (bookmarkProvider
                            .checkPrivateBookmark(bookmarkItem)) {
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
                        if (bookmarkProvider
                            .checkPublicBookmark(bookmarkItem)) {
                          list.add(PopupMenuItem(
                            value: "removeFromPublicBookmark",
                            child: Text("Remove from public bookmark",
                                style: popFontStyle),
                          ));
                        } else {
                          list.add(PopupMenuItem(
                            value: "addToPublicBookmark",
                            child: Text("Add to public bookmark",
                                style: popFontStyle),
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
                        previous.likeNum != next.likeNum))) {
              return true;
            }

            return false;
          },
        ),
        EditorComponent(
            onSubmit: (final String text) async {
              // send reply
              final targetRelays = <String>[];
              targetRelays.addAll(nostr.relayList.write);

              final tags = <Tag>[];
              final er = widget.eventRelation;
              final Set<String> pubkeysMentioned = {};

              // add reply and root tags
              String mark = "reply";
              if (er.rootId == null || er.rootId == "") {
                mark = "root";
              } else {
                tags.add(
                    ["e", widget.event.id, er.rootRelayAddr ?? "", "root"]);
              }
              tags.add(
                  ["e", widget.event.id, widget.event.sources.first, mark]);
              pubkeysMentioned.add(er.pubkey);

              // add p tags inherited from previous event
              var count = 0;
              for (var i = er.tagPList.length - 1; i >= 0; i--) {
                pubkeysMentioned.add(er.pubkey);
                count++;
                if (count >= 5) break;
              }

              // p and q tags from our own inline mentions
              for (final m in RegExp(
                      "\\b(npub1\\w+|nprofile1\\w+|nevent1\\w+|naddr1\\w+|note1\\w+)\\b")
                  .allMatches(text)) {
                final match = m.group(1);
                try {
                  if (match!.startsWith("npub1")) {
                    final pubkey = NIP19.decode(match);
                    pubkeysMentioned.add(pubkey);
                  } else if (match.startsWith("nprofile1")) {
                    final pp = NIP19.decodeNprofile(match);
                    pubkeysMentioned.add(pp!.pubkey);
                  }
                } catch (err) {/***/}
              }

              final ps = pubkeysMentioned.toList();
              final rls = await relaylistLoader.batchLoad(ps);
              var i = 0;
              for (final p in ps) {
                tags.add(["p", p]);
                targetRelays.addAll(rls[i].read);
                i++;
              }

              final event = Event.finalize(
                  nostr.privateKey, EventKind.TEXT_NOTE, tags, text.trim());

              BotToast.showText(
                text: "Publishing event to ${targetRelays.length} relays.",
                duration: const Duration(seconds: 5),
              );
              this.setState(() {
                this.commenting = false;
              });

              final pub = await pool.publish(targetRelays, event);
              if (pub.failure) {
                BotToast.showText(
                    text:
                        "Couldn't publish to any relays, attempted: $targetRelays");
                this.setState(() {
                  this.commenting = true;
                });
                return false;
              }

              BotToast.showText(
                  text: "Event published to ${pub.successCount} relays.");

              // return true here so the editor resets itself
              return true;
            },
            hidden: !commenting),
      ],
    );
  }

  void onPopupSelected(final String value) {
    if (value == "copyEvent") {
      final text = jsonEncode(widget.event.toJson());
      _doCopy(text);
    } else if (value == "copyPubkey") {
      final text = NIP19.encodePubKey(widget.event.pubkey);
      _doCopy(text);
    } else if (value == "copyId") {
      _doCopy(widget.event.id);
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
      filterProvider.addBlock(widget.event.pubkey);
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
    if (this.commenting) {
      this.setState(() {
        this.commenting = false;
      });
      return;
    }

    this.setState(() {
      this.commenting = true;
    });

    // /*final event = await*/ EditorRouter.open(context,
    //     tags: tags, tagsAddedWhenSend: tagsAddedWhenSend, tagPs: tagPs);
    // /*if (event != null) {
    //   eventReactionsProvider.addEventAndHandle(event);
    //   final callback = EventReplyCallback.of(context);
    //   if (callback != null) {
    //     callback.onReply(event);
    //   }
    // }*/
  }

  Future<void> onRepostTap(final String value) async {
    if (value == "boost") {
      nostr.sendRepost(widget.event.id);
      eventReactionsProvider.addRepost(widget.event.id);
    } else if (value == "quote") {
      /* final event = await */ EditorRouter.open(context, initEmbeds: [
        quill.CustomBlockEmbed(CustEmbedTypes.mention_event, widget.event.id)
      ]);
      // print(event);
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

  void onShareTap() {
    if (PlatformUtil.isPC()) {
      final nevent = NIP19.encodeNevent(EventPointer(
        widget.event.id,
        [],
        author: widget.event.pubkey,
        kind: widget.event.kind,
      ));
      launchUrl(Uri.parse("https://njump.me/$nevent"));
      return;
    }

    widget.screenshotController.capture().then(
      (final Uint8List? imageData) async {
        if (imageData != null) {
          final tempFile = await StoreUtil.saveBS2TempFile(
            "png",
            imageData,
          );
          Share.shareXFiles([XFile(tempFile)]);
        }
      },
    ).catchError((final err) {
      print("share error: $err");
    });
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
