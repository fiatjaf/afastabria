import "dart:convert";

import "package:flutter/material.dart";
import "package:flutter_markdown/flutter_markdown.dart";
import "package:provider/provider.dart";
import "package:screenshot/screenshot.dart";

import "package:loure/component/content/content_video_component.dart";
import "package:loure/component/content/markdown/markdown_mention_event_element_builder.dart";
import "package:loure/component/event/event_zap_goals_component.dart";
import "package:loure/component/simple_name_component.dart";
import "package:loure/util/platform_util.dart";
import "package:loure/client/event.dart";
import "package:loure/client/event_kind.dart";
import "package:loure/client/event_relation.dart";
import "package:loure/client/nip23/long_form_info.dart";
import "package:loure/client/nip19/nip19.dart";
import "package:loure/client/nip19/nip19_tlv.dart";
import "package:loure/consts/base.dart";
import "package:loure/consts/base_consts.dart";
import "package:loure/router/routes.dart";
import "package:loure/data/metadata.dart";
import "package:loure/main.dart";
import "package:loure/provider/setting_provider.dart";
import "package:loure/util/router_util.dart";
import "package:loure/util/string_util.dart";
import "package:loure/component/confirm_dialog.dart";
import "package:loure/component/content/content_component.dart";
import "package:loure/component/content/content_decoder.dart";
import "package:loure/component/content/content_image_component.dart";
import "package:loure/component/content/content_link_component.dart";
import "package:loure/component/content/content_tag_component.dart";
import "package:loure/component/content/markdown/markdown_mention_event_inline_syntax.dart";
import "package:loure/component/content/markdown/markdown_mention_user_element_builder.dart";
import "package:loure/component/content/markdown/markdown_mention_user_inline_syntax.dart";
import "package:loure/component/content/markdown/markdown_nevent_inline_syntax.dart";
import "package:loure/component/content/markdown/markdown_nprofile_inline_syntax.dart";
import "package:loure/component/content/markdown/markdown_nrelay_element_builder.dart";
import "package:loure/component/content/markdown/markdown_nrelay_inline_syntax%20copy.dart";
import "package:loure/component/event/event_poll_component.dart";
import "package:loure/component/webview_router.dart";
import "package:loure/component/event/event_quote_component.dart";
import "package:loure/component/event/event_reactions_component.dart";
import "package:loure/component/event/event_top_component.dart";

class EventMainComponent extends StatefulWidget {
  const EventMainComponent({
    required this.screenshotController,
    required this.event,
    super.key,
    this.showReplying = true,
    this.textOnTap,
    this.showVideo = false,
    this.imageListMode = false,
    this.showDetailBtn = true,
    this.showLongContent = false,
    this.showSubject = true,
    this.showCommunity = true,
    this.eventRelation,
    this.showLinkedLongForm = true,
  });
  final ScreenshotController screenshotController;
  final Event event;
  final bool showReplying;
  final Function? textOnTap;
  final bool showVideo;
  final bool imageListMode;
  final bool showDetailBtn;
  final bool showLongContent;
  final bool showSubject;
  final bool showCommunity;
  final EventRelation? eventRelation;
  final bool showLinkedLongForm;

  @override
  State<StatefulWidget> createState() {
    return EventMainComponentState();
  }
}

class EventMainComponentState extends State<EventMainComponent> {
  bool showWarning = false;

  late EventRelation eventRelation;

  @override
  void initState() {
    super.initState();
    if (widget.eventRelation == null) {
      eventRelation = EventRelation.fromEvent(widget.event);
    } else {
      eventRelation = widget.eventRelation!;
    }
  }

  @override
  Widget build(final BuildContext context) {
    final settingProvider = Provider.of<SettingProvider>(context);
    if (eventRelation.id != widget.event.id) {
      // change when thead root load lazy
      eventRelation = EventRelation.fromEvent(widget.event);
    }

    final bool imagePreview = settingProvider.imagePreview == null ||
        settingProvider.imagePreview == OpenStatus.OPEN;
    bool videoPreview = widget.showVideo;
    if (settingProvider.videoPreview != null) {
      videoPreview = settingProvider.videoPreview == OpenStatus.OPEN;
    }

    final themeData = Theme.of(context);
    final hintColor = themeData.hintColor;
    final smallTextSize = themeData.textTheme.bodySmall!.fontSize;
    final largeTextSize = themeData.textTheme.bodyLarge!.fontSize;
    final mainColor = themeData.primaryColor;

    Color? contentCardColor = themeData.cardColor;
    if (contentCardColor == Colors.white) {
      contentCardColor = Colors.grey[300];
    }

    Event? repostEvent;
    if ((widget.event.kind == EventKind.REPOST ||
            widget.event.kind == EventKind.GENERIC_REPOST) &&
        widget.event.content.contains("\"pubkey\"")) {
      try {
        final jsonMap = jsonDecode(widget.event.content);
        repostEvent = Event.fromJson(jsonMap);

        // set source to repost event
        if (repostEvent.id == eventRelation.rootId &&
            StringUtil.isNotBlank(eventRelation.rootRelayAddr)) {
          repostEvent.sources.add(eventRelation.rootRelayAddr!);
        } else if (repostEvent.id == eventRelation.replyId &&
            StringUtil.isNotBlank(eventRelation.replyRelayAddr)) {
          repostEvent.sources.add(eventRelation.replyRelayAddr!);
        }
      } catch (e) {
        print(e);
      }
    }

    if (settingProvider.autoOpenSensitive == OpenStatus.OPEN) {
      showWarning = true;
    }

    List<Widget> list = [];
    if (showWarning || !eventRelation.warning) {
      if (widget.event.kind == EventKind.LONG_FORM) {
        const longFormMargin = EdgeInsets.only(bottom: Base.BASE_PADDING_HALF);

        List<Widget> subList = [];
        final longFormInfo = LongFormInfo.fromEvent(widget.event);
        if (StringUtil.isNotBlank(longFormInfo.title)) {
          subList.add(
            Container(
              margin: longFormMargin,
              child: Text(
                longFormInfo.title!,
                maxLines: 10,
                style: TextStyle(
                  fontSize: largeTextSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        }
        if (longFormInfo.topics.isNotEmpty) {
          List<Widget> topicWidgets = [];
          for (final topic in longFormInfo.topics) {
            topicWidgets.add(ContentTagComponent(tag: "#$topic"));
          }

          subList.add(Container(
            margin: longFormMargin,
            child: Wrap(
              spacing: Base.BASE_PADDING_HALF,
              runSpacing: Base.BASE_PADDING_HALF / 2,
              children: topicWidgets,
            ),
          ));
        }
        if (StringUtil.isNotBlank(longFormInfo.summary)) {
          final Widget summaryTextWidget = Text(
            longFormInfo.summary!,
            style: TextStyle(
              color: hintColor,
            ),
          );
          subList.add(
            Container(
              width: double.infinity,
              margin: longFormMargin,
              child: summaryTextWidget,
            ),
          );
        }
        if (StringUtil.isNotBlank(longFormInfo.image)) {
          subList.add(Container(
            margin: longFormMargin,
            child: ContentImageComponent(
              imageUrl: longFormInfo.image!,
            ),
          ));
        }

        list.add(
          SizedBox(
            width: double.maxFinite,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: subList,
            ),
          ),
        );

        if (widget.showLongContent) {
          final markdownWidget = buildMarkdownWidget(themeData);

          list.add(SizedBox(
            width: double.infinity,
            child: RepaintBoundary(child: markdownWidget),
          ));
        }

        list.add(EventReactionsComponent(
          screenshotController: widget.screenshotController,
          event: widget.event,
          eventRelation: eventRelation,
          showDetailBtn: widget.showDetailBtn,
        ));
      } else if (widget.event.kind == EventKind.REPOST ||
          widget.event.kind == EventKind.GENERIC_REPOST) {
        list.add(Container(
          alignment: Alignment.centerLeft,
          child: const Text("Boost:"),
        ));
        if (repostEvent != null) {
          list.add(EventQuoteComponent(
            event: repostEvent,
            showVideo: widget.showVideo,
          ));
        } else if (StringUtil.isNotBlank(eventRelation.rootId)) {
          list.add(EventQuoteComponent(
            id: eventRelation.rootId,
            showVideo: widget.showVideo,
          ));
        } else {
          list.add(
            buildContentWidget(settingProvider, imagePreview, videoPreview),
          );
        }
      } else {
        if (widget.showReplying && eventRelation.tagPList.isNotEmpty) {
          final textStyle = TextStyle(
            color: hintColor,
            fontSize: smallTextSize,
          );
          List<Widget> replyingList = [];
          final length = eventRelation.tagPList.length;
          replyingList.add(Text(
            "${"Replying"}: ",
            style: textStyle,
          ));
          for (var index = 0; index < length; index++) {
            final p = eventRelation.tagPList[index];
            final isLast = index < length - 1 ? false : true;
            replyingList.add(EventReplyingComponent(pubkey: p));
            if (!isLast) {
              replyingList.add(Text(
                " & ",
                style: textStyle,
              ));
            }
          }
          list.add(Container(
            width: double.maxFinite,
            padding: const EdgeInsets.only(
              bottom: Base.BASE_PADDING_HALF,
            ),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: replyingList,
            ),
          ));
        } else {
          // hide the reply note subject!
          if (widget.showSubject) {
            if (StringUtil.isNotBlank(eventRelation.subject)) {
              list.add(Container(
                width: double.infinity,
                alignment: Alignment.centerLeft,
                margin: const EdgeInsets.only(bottom: Base.BASE_PADDING_HALF),
                child: Text(
                  eventRelation.subject!,
                  maxLines: 10,
                  style: TextStyle(
                    fontSize: largeTextSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ));
            }
          }
        }

        list.add(
          buildContentWidget(settingProvider, imagePreview, videoPreview),
        );

        if (widget.event.kind == EventKind.POLL) {
          list.add(EventPollComponent(
            event: widget.event,
          ));
        } else if (widget.event.kind == EventKind.ZAP_GOALS ||
            StringUtil.isNotBlank(eventRelation.zapraiser)) {
          list.add(EventZapGoalsComponent(
            event: widget.event,
          ));
        }

        if (widget.event.kind == EventKind.FILE_HEADER) {
          String? m;
          String? url;
          for (final tag in widget.event.tags) {
            if (tag.length > 1) {
              final key = tag[0];
              final value = tag[1];
              if (key == "url") {
                url = value;
              } else if (key == "m") {
                m = value;
              }
            }
          }

          if (StringUtil.isNotBlank(url)) {
            //  show and decode depend m
            if (StringUtil.isNotBlank(m)) {
              if (m!.indexOf("image/") == 0) {
                list.add(ContentImageComponent(imageUrl: url!));
              } else if (m.indexOf("video/") == 0 &&
                  widget.showVideo &&
                  !PlatformUtil.isPC()) {
                list.add(ContentVideoComponent(url: url!));
              } else {
                list.add(ContentLinkComponent(link: url!));
              }
            } else {
              final fileType = ContentDecoder.getPathType(url!);
              if (fileType == "image") {
                list.add(ContentImageComponent(imageUrl: url));
              } else if (fileType == "video" && !PlatformUtil.isPC()) {
                if (settingProvider.videoPreview != OpenStatus.OPEN &&
                    (settingProvider.videoPreviewInList == OpenStatus.OPEN ||
                        widget.showVideo)) {
                  list.add(ContentVideoComponent(url: url));
                } else {
                  list.add(ContentLinkComponent(link: url));
                }
              } else {
                list.add(ContentLinkComponent(link: url));
              }
            }
          }
        }

        if (eventRelation.aId != null &&
            eventRelation.aId!.kind == EventKind.LONG_FORM &&
            widget.showLinkedLongForm) {
          list.add(EventQuoteComponent(
            aId: eventRelation.aId!,
          ));
        }

        if (widget.event.kind != EventKind.ZAP) {
          list.add(EventReactionsComponent(
            screenshotController: widget.screenshotController,
            event: widget.event,
            eventRelation: eventRelation,
            showDetailBtn: widget.showDetailBtn,
          ));
        } else {
          list.add(Container(
            height: Base.BASE_PADDING,
          ));
        }
      }
    } else {
      list.add(buildWarningWidget(largeTextSize!, mainColor));
    }

    List<Widget> eventAllList = [];

    if (eventRelation.aId != null &&
        eventRelation.aId!.kind == EventKind.COMMUNITY_DEFINITION &&
        widget.showCommunity) {
      final communityTitle = Row(
        children: [
          Icon(
            Icons.groups,
            size: largeTextSize,
            color: hintColor,
          ),
          Container(
            margin: const EdgeInsets.only(
              left: Base.BASE_PADDING_HALF,
              right: 3,
            ),
            child: Text(
              "From",
              style: TextStyle(
                color: hintColor,
                fontSize: smallTextSize,
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              RouterUtil.router(
                  context, RouterPath.COMMUNITY_DETAIL, eventRelation.aId);
            },
            child: Text(
              eventRelation.aId!.identifier,
              style: TextStyle(
                fontSize: smallTextSize,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      );

      eventAllList.add(Container(
        padding: const EdgeInsets.only(
          left: Base.BASE_PADDING + 4,
          right: Base.BASE_PADDING + 4,
          bottom: Base.BASE_PADDING_HALF,
        ),
        child: communityTitle,
      ));
    }

    eventAllList.add(EventTopComponent(
      event: widget.event,
    ));

    eventAllList.add(Container(
      width: double.maxFinite,
      padding: const EdgeInsets.only(
        left: Base.BASE_PADDING,
        right: Base.BASE_PADDING,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: list,
      ),
    ));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: eventAllList,
    );
  }

  bool forceShowLongContnet = false;

  bool hideLongContent = false;

  Widget buildContentWidget(final SettingProvider settingProvider,
      final bool imagePreview, final bool videoPreview) {
    final main = SizedBox(
      width: double.maxFinite,
      child: ContentComponent(
        content: widget.event.content,
        event: widget.event,
        textOnTap: widget.textOnTap,
        showImage: imagePreview,
        showVideo: videoPreview,
        showLinkPreview: settingProvider.linkPreview == OpenStatus.OPEN,
        imageListMode: widget.imageListMode,
      ),
      // child: Column(
      //   crossAxisAlignment: CrossAxisAlignment.start,
      //   mainAxisSize: MainAxisSize.min,
      //   children: ContentDecoder.decode(
      //     context,
      //     null,
      //     widget.event,
      //     textOnTap: widget.textOnTap,
      //     showImage: imagePreview,
      //     showVideo: videoPreview,
      //     showLinkPreview: _settingProvider.linkPreview == OpenStatus.OPEN,
      //     imageListMode: widget.imageListMode,
      //   ),
      // ),
    );

    return main;
  }

  buildMarkdownWidget(final ThemeData themeData) {
    // handle old mention, replace to NIP-27 style: nostr:note1xxxx or nostr:npub1xxx
    var content = widget.event.content;
    final tagLength = widget.event.tags.length;
    for (var i = 0; i < tagLength; i++) {
      final tag = widget.event.tags[i];
      String? link;

      if (tag.length > 1) {
        final key = tag[0];
        final value = tag[1];
        if (key == "e") {
          link = "nostr:${Nip19.encodeNoteId(value)}";
        } else if (key == "p") {
          link = "nostr:${Nip19.encodePubKey(value)}";
        }
      }

      if (StringUtil.isNotBlank(link)) {
        content = content.replaceAll("#[$i]", link!);
      }
    }

    return MarkdownBody(
      data: content,
      selectable: true,
      builders: {
        MarkdownMentionUserElementBuilder.TAG:
            MarkdownMentionUserElementBuilder(),
        MarkdownMentionEventElementBuilder.TAG:
            MarkdownMentionEventElementBuilder(),
        MarkdownNrelayElementBuilder.TAG: MarkdownNrelayElementBuilder(),
      },
      blockSyntaxes: const [],
      inlineSyntaxes: [
        MarkdownMentionEventInlineSyntax(),
        MarkdownMentionUserInlineSyntax(),
        MarkdownNeventInlineSyntax(),
        MarkdownNprofileInlineSyntax(),
        MarkdownNrelayInlineSyntax(),
      ],
      imageBuilder: (final Uri uri, final String? title, final String? alt) {
        if (settingProvider.imagePreview == OpenStatus.CLOSE) {
          return ContentLinkComponent(
            link: uri.toString(),
            title: title,
          );
        }
        return ContentImageComponent(imageUrl: uri.toString());
      },
      styleSheet: MarkdownStyleSheet(
        a: TextStyle(
          color: themeData.primaryColor,
          decoration: TextDecoration.underline,
        ),
      ),
      onTapLink:
          (final String text, final String? href, final String title) async {
        // print("text $text href $href title $title");
        if (StringUtil.isNotBlank(href)) {
          if (href!.indexOf("http") == 0) {
            WebViewRouter.open(context, href);
          } else if (href.indexOf("nostr:") == 0) {
            final link = href.replaceFirst("nostr:", "");
            if (Nip19.isPubkey(link)) {
              // jump user page
              final pubkey = Nip19.decode(link);
              if (StringUtil.isNotBlank(pubkey)) {
                RouterUtil.router(context, RouterPath.USER, pubkey);
              }
            } else if (NIP19Tlv.isNprofile(link)) {
              final nprofile = NIP19Tlv.decodeNprofile(link);
              if (nprofile != null) {
                RouterUtil.router(context, RouterPath.USER, nprofile.pubkey);
              }
            } else if (Nip19.isNoteId(link)) {
              final noteId = Nip19.decode(link);
              if (StringUtil.isNotBlank(noteId)) {
                RouterUtil.router(context, RouterPath.EVENT_DETAIL, noteId);
              }
            } else if (NIP19Tlv.isNevent(link)) {
              final nevent = NIP19Tlv.decodeNevent(link);
              if (nevent != null) {
                RouterUtil.router(context, RouterPath.EVENT_DETAIL, nevent.id);
              }
            } else if (NIP19Tlv.isNaddr(link)) {
              final naddr = NIP19Tlv.decodeNaddr(link);
              if (naddr != null) {
                RouterUtil.router(context, RouterPath.EVENT_DETAIL, naddr.id);
              }
            } else if (NIP19Tlv.isNrelay(link)) {
              final nrelay = NIP19Tlv.decodeNrelay(link);
              if (nrelay != null) {
                final result = await ConfirmDialog.show(
                    context, "Add this relay to local");
                if (result == true) {
                  nostr.relayList.add(nrelay.addr, true, true);
                }
              }
            }
          }
        }
      },
    );
  }

  Widget buildWarningWidget(final double largeTextSize, final Color mainColor) {
    return Container(
      margin: const EdgeInsets.only(
          bottom: Base.BASE_PADDING, top: Base.BASE_PADDING),
      width: double.maxFinite,
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning),
              Container(
                margin: const EdgeInsets.only(left: Base.BASE_PADDING_HALF),
                child: Text(
                  "Content warning",
                  style: TextStyle(fontSize: largeTextSize),
                ),
              )
            ],
          ),
          const Text("This note contains sensitive content"),
          GestureDetector(
            onTap: () {
              setState(() {
                showWarning = true;
              });
            },
            child: Container(
              margin: const EdgeInsets.only(top: Base.BASE_PADDING_HALF),
              padding: const EdgeInsets.only(
                top: 4,
                bottom: 4,
                left: Base.BASE_PADDING,
                right: Base.BASE_PADDING,
              ),
              decoration: BoxDecoration(
                color: mainColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                "Show",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class EventReplyingComponent extends StatefulWidget {
  const EventReplyingComponent({required this.pubkey, super.key});
  final String pubkey;

  @override
  State<StatefulWidget> createState() {
    return EventReplyingComponentState();
  }
}

class EventReplyingComponentState extends State<EventReplyingComponent> {
  @override
  Widget build(final BuildContext context) {
    return GestureDetector(
      onTap: () {
        RouterUtil.router(context, RouterPath.USER, widget.pubkey);
      },
      child: FutureBuilder(
        future: metadataLoader.load(widget.pubkey),
        initialData: Metadata.blank(widget.pubkey),
        builder: (final context, final snapshot) {
          final metadata = snapshot.data!;

          final themeData = Theme.of(context);
          final hintColor = themeData.hintColor;
          final smallTextSize = themeData.textTheme.bodySmall!.fontSize;
          final displayName =
              SimpleNameComponent.getSimpleName(widget.pubkey, metadata);

          return Text(
            displayName,
            style: TextStyle(
              color: hintColor,
              fontSize: smallTextSize,
              // fontWeight: FontWeight.bold,
            ),
          );
        },
      ),
    );
  }
}
