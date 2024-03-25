import "dart:convert";

import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "package:screenshot/screenshot.dart";

import "package:loure/main.dart";
import "package:loure/provider/community_approved_provider.dart";
import "package:loure/util/string_util.dart";
import "package:loure/client/event_kind.dart";
import "package:loure/client/event.dart";
import "package:loure/client/event_relation.dart";
import "package:loure/consts/base.dart";
import "package:loure/router/routes.dart";
import "package:loure/util/router_util.dart";
import "package:loure/component/event/event_bitcion_icon_component.dart";
import "package:loure/component/event/event_main_component.dart";

class EventListComponent extends StatefulWidget {
  const EventListComponent({
    required this.event,
    super.key,
    this.jumpable = true,
    this.showVideo = false,
    this.imageListMode = true,
    this.showDetailBtn = true,
    this.showLongContent = false,
    this.showCommunity = true,
  });
  final Event event;
  final bool jumpable;
  final bool showVideo;
  final bool imageListMode;
  final bool showDetailBtn;
  final bool showLongContent;
  final bool showCommunity;

  @override
  State<StatefulWidget> createState() {
    return EventListComponentState();
  }
}

class EventListComponentState extends State<EventListComponent> {
  final ScreenshotController screenshotController = ScreenshotController();

  @override
  Widget build(final BuildContext context) {
    final themeData = Theme.of(context);
    final cardColor = themeData.cardColor;
    final eventRelation = EventRelation.fromEvent(widget.event);

    Widget main = Screenshot(
      controller: screenshotController,
      child: Container(
        color: cardColor,
        margin: const EdgeInsets.only(bottom: Base.BASE_PADDING_HALF),
        padding: const EdgeInsets.only(
          top: Base.BASE_PADDING,
          // bottom: Base.BASE_PADDING,
        ),
        child: EventMainComponent(
          screenshotController: screenshotController,
          event: widget.event,
          textOnTap: widget.jumpable ? jumpToThread : null,
          showVideo: widget.showVideo,
          imageListMode: widget.imageListMode,
          showDetailBtn: widget.showDetailBtn,
          showLongContent: widget.showLongContent,
          showCommunity: widget.showCommunity,
          eventRelation: eventRelation,
        ),
      ),
    );

    if (widget.event.kind == EventKind.ZAP) {
      main = Stack(
        children: [
          main,
          const Positioned(
            top: -35,
            right: -10,
            child: EventBitcionIconComponent(),
          ),
        ],
      );
    }

    final Widget approvedWrap = Selector<CommunityApprovedProvider, bool>(
        builder: (final context, final approved, final child) {
      if (approved) {
        return main;
      }

      return Container();
    }, selector: (final context, final provider) {
      return provider.check(widget.event.pubkey, widget.event.id,
          aId: eventRelation.aId);
    });

    if (widget.jumpable) {
      return GestureDetector(
        onTap: jumpToThread,
        child: approvedWrap,
      );
    } else {
      return approvedWrap;
    }
  }

  void jumpToThread() {
    if (widget.event.kind == EventKind.REPOST) {
      // try to find target event
      if (widget.event.content.contains("\"pubkey\"")) {
        try {
          final jsonMap = jsonDecode(widget.event.content);
          final repostEvent = Event.fromJson(jsonMap);
          RouterUtil.router(context, RouterPath.THREAD_DETAIL, repostEvent);
          return;
        } catch (e) {
          print(e);
        }
      }

      final eventRelation = EventRelation.fromEvent(widget.event);
      if (StringUtil.isNotBlank(eventRelation.rootId)) {
        final event = nostr.idIndex[eventRelation.rootId!];
        if (event != null) {
          RouterUtil.router(context, RouterPath.THREAD_DETAIL, event);
          return;
        }
      }
    }
    RouterUtil.router(context, RouterPath.THREAD_DETAIL, widget.event);
  }
}
