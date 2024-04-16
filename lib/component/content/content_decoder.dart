import "package:flutter/material.dart";
import "package:loure/client/event_kind.dart";
import "package:loure/component/content/content_event_tag_infos.dart";

import "package:loure/client/event.dart";
import "package:loure/client/nip19/nip19.dart";
import "package:loure/consts/base.dart";
import "package:loure/consts/base64.dart";
import "package:loure/util/platform_util.dart";
import "package:loure/util/string_util.dart";
import "package:loure/component/event/event_quote_component.dart";
import "package:loure/component/translate/line_translate_component.dart";
import "package:loure/component/content/content_custom_emoji_component.dart";
import "package:loure/component/content/content_image_component.dart";
import "package:loure/component/content/content_link_component.dart";
import "package:loure/component/content/content_link_pre_component.dart";
import "package:loure/component/content/content_mention_user_component.dart";
// import "package:loure/component/content/content_relay_component.dart";
import "package:loure/component/content/content_tag_component.dart";
import "package:loure/component/content/content_video_component.dart";

class ContentDecoder {
  static const NOTE_REFERENCES = "nostr:";
  static const NOTE_REFERENCES_AT = "@nostr:";
  static const MENTION_USER = "@npub";
  static const MENTION_NOTE = "@note";
  static const int NPUB_LENGTH = 63;
  static const int NOTEID_LENGTH = 63;

  static String _addToHandledStr(final String handledStr, final String subStr) {
    if (StringUtil.isBlank(handledStr)) {
      return subStr;
    } else {
      return "$handledStr $subStr";
    }
  }

  static String _closeHandledStr(
      final String handledStr, final List<dynamic> inlines) {
    if (StringUtil.isNotBlank(handledStr)) {
      // inlines.add(Text(handledStr));
      inlines.add(handledStr);
    }
    return "";
  }

  static void _closeInlines(
      final List<dynamic> inlines, final List<Widget> list,
      {final Function? textOnTap}) {
    if (inlines.isNotEmpty) {
      if (inlines.length == 1) {
        if (inlines[0] is String) {
          // list.add(TextTranslateComponent(
          //   inlines[0],
          //   textOnTap: textOnTap,
          // ));
          list.add(LineTranslateComponent(
            [inlines[0]],
            textOnTap: textOnTap,
          ));
        } else {
          list.add(inlines[0]);
        }
      } else {
        // List<InlineSpan> spans = [];
        // for (var inline in inlines) {
        //   if (inline is String) {
        //     spans.add(WidgetSpan(
        //         child: TextTranslateComponent(
        //       inline + " ",
        //       textOnTap: textOnTap,
        //     )));
        //   } else {
        //     spans.add(WidgetSpan(child: inline));
        //   }
        // }
        // list.add(Text.rich(TextSpan(children: spans)));

        list.add(LineTranslateComponent(
          [...inlines],
          textOnTap: textOnTap,
        ));
      }
      inlines.clear();
    }
  }

  static ContentDecoderInfo _decodeTest(String content) {
    content = content.trim();
    content = content.replaceAll("\r\n", "\n");
    content = content.replaceAll("\n\n", "\n");
    final strs = content.split("\n");

    final ContentDecoderInfo info = ContentDecoderInfo();
    for (final str in strs) {
      // List<dynamic> inlines = [];
      // const String handledStr = "";

      final subStrs = str.split(" ");
      info.strs.add(subStrs);
      for (final subStr in subStrs) {
        if (subStr.indexOf("http") == 0) {
          // link, image, video etc
          final pathType = getPathType(subStr);
          if (pathType == "image") {
            info.imageNum++;
          }
        }
      }
    }

    return info;
  }

  @Deprecated(
      "This method had bean Deprecated, it should insteaded by ContentComponent")
  static List<Widget> decode(
    final BuildContext context,
    String? content,
    final Event? event, {
    final Function? textOnTap,
    final bool showImage = true,
    final bool showVideo = false,
    final bool showLinkPreview = true,
    final bool imageListMode = false,
  }) {
    if (StringUtil.isBlank(content) && event != null) {
      content = event.content;
    }
    List<Widget> list = [];
    List<String> imageList = [];

    final decodeInfo = _decodeTest(content!);
    ContentEventTagInfos? tagInfos;
    if (event != null) {
      tagInfos = ContentEventTagInfos.fromEvent(event);
    }

    for (final subStrs in decodeInfo.strs) {
      List<dynamic> inlines = [];
      String handledStr = "";

      ///
      /// 1、str: add to handledStr
      /// 2、inline: put handledStr to inlines, put currentInline to inlines, new a new handledStr
      /// 3、block: put handledStr to inlines, put inlines to list as a line, put block to list as a line, new a new handledStr
      /// 4、if handledStr not empty, put to inlines, put inlines to list as a line
      ///
      for (var subStr in subStrs) {
        if (subStr.indexOf("http") == 0) {
          // link, image, video etc
          final pathType = getPathType(subStr);
          if (pathType == "image") {
            if (showImage) {
              imageList.add(subStr);
              if (imageListMode && decodeInfo.imageNum > 1) {
                // inline
                handledStr = handledStr.trim();
                final imagePlaceholder = Container(
                  margin: const EdgeInsets.only(left: 4),
                  child: const Icon(
                    Icons.image,
                    size: 15,
                  ),
                );
                if (StringUtil.isBlank(handledStr) && inlines.isEmpty) {
                  // add to pre line
                  final listLength = list.length;
                  if (listLength > 0) {
                    final lastListWidget = list[listLength - 1];
                    List<InlineSpan> spans = [];
                    if (lastListWidget is SelectableText) {
                      if (lastListWidget.data != null) {
                        spans.add(TextSpan(text: lastListWidget.data));
                      } else if (lastListWidget.textSpan != null) {
                        spans.addAll(lastListWidget.textSpan!.children!);
                      }
                    } else {
                      spans.add(WidgetSpan(child: lastListWidget));
                    }
                    spans.add(WidgetSpan(child: imagePlaceholder));

                    list[listLength - 1] = SelectableText.rich(
                      TextSpan(children: spans),
                      onTap: () {
                        if (textOnTap != null) {
                          textOnTap();
                        }
                      },
                    );
                  }
                } else {
                  if (StringUtil.isNotBlank(handledStr)) {
                    handledStr = _closeHandledStr(handledStr, inlines);
                  }
                  inlines.add(imagePlaceholder);
                }
              } else {
                // block
                handledStr = _closeHandledStr(handledStr, inlines);
                _closeInlines(inlines, list, textOnTap: textOnTap);
                final imageIndex = imageList.length - 1;
                final imageWidget = ContentImageComponent(
                  imageUrl: subStr,
                  imageList: imageList,
                  imageIndex: imageIndex,
                );
                list.add(imageWidget);
              }
            } else {
              // inline
              handledStr = _closeHandledStr(handledStr, inlines);
              inlines.add(ContentLinkComponent(link: subStr));
            }
          } else if (pathType == "video") {
            if (showVideo && !PlatformUtil.isPC()) {
              // block
              handledStr = _closeHandledStr(handledStr, inlines);
              _closeInlines(inlines, list, textOnTap: textOnTap);
              final w = ContentVideoComponent(url: subStr);
              list.add(w);
            } else {
              // inline
              handledStr = _closeHandledStr(handledStr, inlines);
              inlines.add(ContentLinkComponent(link: subStr));
            }
            // // TODO need to handle, this is temp handle
            // handledStr = _addToHandledStr(handledStr, subStr);
          } else if (pathType == "link") {
            if (!showLinkPreview) {
              // inline
              handledStr = _closeHandledStr(handledStr, inlines);
              inlines.add(ContentLinkComponent(link: subStr));
            } else {
              // block
              handledStr = _closeHandledStr(handledStr, inlines);
              _closeInlines(inlines, list, textOnTap: textOnTap);
              final w = ContentLinkPreComponent(
                link: subStr,
              );
              list.add(w);
              // }
            }
          }
        } else if (subStr.indexOf(NOTE_REFERENCES) == 0 ||
            subStr.indexOf(NOTE_REFERENCES_AT) == 0) {
          var key = subStr.replaceFirst(NOTE_REFERENCES_AT, "");
          key = key.replaceFirst(NOTE_REFERENCES, "");

          String? otherStr;

          if (NIP19.isPubkey(key)) {
            // inline
            // mention user
            if (key.length > NPUB_LENGTH) {
              otherStr = key.substring(NPUB_LENGTH);
              key = key.substring(0, NPUB_LENGTH);
            }
            key = NIP19.decode(key);
            handledStr = _closeHandledStr(handledStr, inlines);
            inlines.add(ContentMentionUserComponent(pubkey: key));
          } else if (NIP19.isNoteId(key)) {
            // block
            if (key.length > NOTEID_LENGTH) {
              otherStr = key.substring(NOTEID_LENGTH);
              key = key.substring(0, NOTEID_LENGTH);
            }
            key = NIP19.decode(key);
            handledStr = _closeHandledStr(handledStr, inlines);
            _closeInlines(inlines, list, textOnTap: textOnTap);
            final widget = EventQuoteComponent(
              id: key,
              showVideo: showVideo,
            );
            list.add(widget);
          } else if (NIP19.isNprofile(key)) {
            final nprofile = NIP19.decodeNprofile(key);
            if (nprofile != null) {
              // inline
              // mention user
              handledStr = _closeHandledStr(handledStr, inlines);
              inlines.add(ContentMentionUserComponent(pubkey: nprofile.pubkey));
            } else {
              handledStr = _addToHandledStr(handledStr, subStr);
            }
            // } else if (NIP19.isNrelay(key)) {
            //   final nrelay = NIP19.decodeNrelay(key);
            //   if (nrelay != null) {
            //     // inline
            //     handledStr = _closeHandledStr(handledStr, inlines);
            //     inlines.add(ContentRelayComponent(nrelay.addr));
            //   } else {
            //     handledStr = _addToHandledStr(handledStr, subStr);
            //   }
          } else if (NIP19.isNevent(key)) {
            final nevent = NIP19.decodeNevent(key);
            if (nevent != null) {
              // block
              handledStr = _closeHandledStr(handledStr, inlines);
              _closeInlines(inlines, list, textOnTap: textOnTap);
              final widget = EventQuoteComponent(
                id: nevent.id,
                showVideo: showVideo,
              );
              list.add(widget);
            } else {
              handledStr = _addToHandledStr(handledStr, subStr);
            }
          } else if (NIP19.isNaddr(key)) {
            final naddr = NIP19.decodeNaddr(key);
            if (naddr != null) {
              if (StringUtil.isNotBlank(naddr.identifier) &&
                  naddr.kind == EventKind.TEXT_NOTE) {
                // block
                handledStr = _closeHandledStr(handledStr, inlines);
                _closeInlines(inlines, list, textOnTap: textOnTap);
                final widget = EventQuoteComponent(
                  id: naddr.identifier,
                  showVideo: showVideo,
                );
                list.add(widget);
              } else if (StringUtil.isNotBlank(naddr.pubkey) &&
                  naddr.kind == EventKind.METADATA) {
                // inline
                handledStr = _closeHandledStr(handledStr, inlines);
                inlines.add(ContentMentionUserComponent(pubkey: naddr.pubkey));
              } else {
                handledStr = _addToHandledStr(handledStr, subStr);
              }
            } else {
              handledStr = _addToHandledStr(handledStr, subStr);
            }
          } else {
            handledStr = _addToHandledStr(handledStr, subStr);
          }

          if (StringUtil.isNotBlank(otherStr)) {
            handledStr = _addToHandledStr(handledStr, otherStr!);
          }
        } else if (subStr.indexOf(MENTION_USER) == 0) {
          var key = subStr.replaceFirst("@", "");
          // inline
          // mention user
          key = NIP19.decode(key);
          handledStr = _closeHandledStr(handledStr, inlines);
          inlines.add(ContentMentionUserComponent(pubkey: key));
        } else if (subStr.indexOf(MENTION_NOTE) == 0) {
          var key = subStr.replaceFirst("@", "");
          // block
          key = NIP19.decode(key);
          handledStr = _closeHandledStr(handledStr, inlines);
          _closeInlines(inlines, list, textOnTap: textOnTap);
          final widget = EventQuoteComponent(
            id: key,
            showVideo: showVideo,
          );
          list.add(widget);
        } else if (subStr.indexOf("#[") == 0 &&
            subStr.length > 3 &&
            event != null) {
          // mention
          final endIndex = subStr.indexOf("]");
          final indexStr = subStr.substring(2, endIndex);
          final index = int.tryParse(indexStr);
          if (index != null && event.tags.length > index) {
            final tag = event.tags[index];
            if (tag.length > 1) {
              final tagType = tag[0];
              if (tagType == "e") {
                // block
                // mention event
                handledStr = _closeHandledStr(handledStr, inlines);
                _closeInlines(inlines, list, textOnTap: textOnTap);
                final widget = EventQuoteComponent(
                  id: tag[1],
                  showVideo: showVideo,
                );
                list.add(widget);
              } else if (tagType == "p") {
                // inline
                // mention user
                handledStr = _closeHandledStr(handledStr, inlines);
                inlines.add(ContentMentionUserComponent(pubkey: tag[1]));
              } else {
                handledStr = _addToHandledStr(handledStr, subStr);
              }
            }
          }
        } else if (subStr.indexOf("#") == 0 &&
            subStr.indexOf("[") != 1 &&
            subStr.length > 1 &&
            subStr.substring(1) != "#") {
          // inline
          // tag
          var extralStr = "";
          final length = subStr.length;
          if (tagInfos != null) {
            for (final hashtagInfo in tagInfos.tagEntryInfos) {
              final hashtag = hashtagInfo.key;
              final hashtagLength = hashtagInfo.value;
              if (subStr.indexOf(hashtag) == 1) {
                // dua to tagEntryInfos is sorted, so this is the match hashtag
                if (hashtagLength > 0 && length > hashtagLength) {
                  // this str's length is more then hastagLength, maybe there are some extralStr.
                  extralStr = subStr.substring(hashtagLength + 1);
                  subStr = "#$hashtag";
                }
                break;
              }
            }
          }

          handledStr = _closeHandledStr(handledStr, inlines);
          inlines.add(ContentTagComponent(tag: subStr));
          if (StringUtil.isNotBlank(extralStr)) {
            handledStr = _addToHandledStr(handledStr, extralStr);
          }
        } else {
          final length = subStr.length;
          if (length > 2) {
            if (subStr.substring(0, 1) == ":" &&
                subStr.substring(length - 1) == ":" &&
                tagInfos != null) {
              final emojiKey = subStr.substring(1, length - 1);
              final imagePath = tagInfos.emojiMap[emojiKey];
              // var imagePath = tagInfos.emojiMap[subStr];
              if (StringUtil.isNotBlank(imagePath)) {
                handledStr = _closeHandledStr(handledStr, inlines);
                inlines.add(ContentCustomEmojiComponent(imagePath: imagePath!));
                continue;
              }
            }
          }

          handledStr = _addToHandledStr(handledStr, subStr);
        }
      }

      handledStr = _closeHandledStr(handledStr, inlines);
      _closeInlines(inlines, list, textOnTap: textOnTap);
    }

    if (imageListMode && decodeInfo.imageNum > 1) {
      // showImageList in bottom
      List<Widget> imageWidgetList = [];
      var index = 0;
      for (final image in imageList) {
        imageWidgetList.add(SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.only(right: Base.BASE_PADDING_HALF),
            width: CONTENT_IMAGE_LIST_HEIGHT,
            height: CONTENT_IMAGE_LIST_HEIGHT,
            child: ContentImageComponent(
              imageUrl: image,
              imageList: imageList,
              imageIndex: index,
              height: CONTENT_IMAGE_LIST_HEIGHT,
              width: CONTENT_IMAGE_LIST_HEIGHT,
              // imageBoxFix: BoxFit.fitWidth,
            ),
          ),
        ));
        index++;
      }

      list.add(SizedBox(
        height: CONTENT_IMAGE_LIST_HEIGHT,
        width: double.infinity,
        child: CustomScrollView(
          slivers: imageWidgetList,
          scrollDirection: Axis.horizontal,
        ),
      ));
    }

    return list;
  }

  static const double CONTENT_IMAGE_LIST_HEIGHT = 90;

  static String? getPathType(String path) {
    if (path.indexOf(BASE64.PREFIX) == 0) {
      return "image";
    }

    var strs = path.split("?");
    strs = strs[0].split("#");
    final index = strs[0].lastIndexOf(".");
    if (index == -1) {
      return null;
    }

    path = strs[0];
    var n = path.substring(index);
    n = n.toLowerCase();

    if (n == ".png" ||
        n == ".jpg" ||
        n == ".jpeg" ||
        n == ".gif" ||
        n == ".webp") {
      return "image";
    } else if (n == ".mp4" || n == ".mov" || n == ".wmv" || n == ".m3u8") {
      return "video";
    } else {
      if (path.contains("void.cat/d/")) {
        return "image";
      }
      return "link";
    }
  }
}

class ContentDecoderInfo {
  int imageNum = 0;
  List<List<String>> strs = [];
}
