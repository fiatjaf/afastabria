import "package:flutter/material.dart";
import "package:screenshot/screenshot.dart";

import "package:loure/client/aid.dart";
import "package:loure/main.dart";
import "package:loure/client/event.dart";
import "package:loure/consts/base.dart";
import "package:loure/router/routes.dart";
import "package:loure/util/router_util.dart";
import "package:loure/component/event/event_main_component.dart";

// ignore: must_be_immutable
class EventQuoteComponent extends StatefulWidget {
  EventQuoteComponent({
    super.key,
    this.event,
    this.id,
    this.aId,
    this.showVideo = false,
  });
  Event? event;
  String? id;
  AId? aId;
  bool showVideo;

  @override
  State<StatefulWidget> createState() {
    return _EventQuoteComponent();
  }
}

class _EventQuoteComponent extends State<EventQuoteComponent> {
  ScreenshotController screenshotController = ScreenshotController();
  Future<Event?>? eventFuture;

  @override
  void initState() {
    super.initState();

    if (widget.aId != null) {
      this.eventFuture = nostr.getByAddress(widget.aId!);
    } else if (widget.id != null) {
      this.eventFuture = nostr.getByID(widget.id!);
    }
  }

  @override
  Widget build(final BuildContext context) {
    final themeData = Theme.of(context);
    final cardColor = themeData.cardColor;
    final boxDecoration = BoxDecoration(
      color: cardColor,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.2),
          offset: const Offset(0, 0),
          blurRadius: 10,
          spreadRadius: 0,
        ),
      ],
    );

    if (widget.event != null) {
      return buildEventWidget(widget.event!, cardColor, boxDecoration);
    }

    return FutureBuilder(
      future: this.eventFuture,
      initialData: null,
      builder: (final context, final as) {
        if (as.data == null) {
          return buildBlankWidget(boxDecoration);
        }
        return buildEventWidget(as.data!, cardColor, boxDecoration);
      },
    );
  }

  Widget buildEventWidget(final Event event, final Color cardColor,
      final BoxDecoration boxDecoration) {
    return Screenshot(
      controller: screenshotController,
      child: Container(
        padding: const EdgeInsets.only(top: Base.BASE_PADDING),
        margin: const EdgeInsets.all(Base.BASE_PADDING),
        decoration: boxDecoration,
        child: GestureDetector(
          onTap: () {
            jumpToThread(event);
          },
          behavior: HitTestBehavior.translucent,
          child: EventMainComponent(
            screenshotController: screenshotController,
            event: event,
            showReplying: false,
            textOnTap: () {
              jumpToThread(event);
            },
            showVideo: widget.showVideo,
            imageListMode: true,
          ),
        ),
      ),
    );
  }

  Widget buildBlankWidget(final BoxDecoration boxDecoration) {
    return Container(
      margin: const EdgeInsets.all(Base.BASE_PADDING),
      height: 60,
      decoration: boxDecoration,
      child: const Center(child: Text("Note loading")),
    );
  }

  void jumpToThread(final Event event) {
    RouterUtil.router(context, RouterPath.THREAD_DETAIL, event);
  }
}
