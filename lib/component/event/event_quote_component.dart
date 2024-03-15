import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';

import 'package:loure/client/aid.dart';
import 'package:loure/main.dart';
import 'package:loure/provider/replaceable_event_provider.dart';
import 'package:loure/client/event.dart';
import 'package:loure/client/filter.dart';
import 'package:loure/consts/base.dart';
import 'package:loure/consts/router_path.dart';
import 'package:loure/util/router_util.dart';
import 'package:loure/component/event/event_main_component.dart';

// ignore: must_be_immutable
class EventQuoteComponent extends StatefulWidget {
  Event? event;
  String? id;
  AId? aId;
  bool showVideo;

  EventQuoteComponent({
    super.key,
    this.event,
    this.id,
    this.aId,
    this.showVideo = false,
  });

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

    if (widget.id != null) {
      var evt = nostr.eventIndex[widget.id];
      if (evt != null) {
        eventFuture = Future.value(evt);
      } else {
        eventFuture =
            nostr.pool.querySingle(nostr.ID_RELAYS, Filter(ids: [widget.id!]));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    var themeData = Theme.of(context);
    var cardColor = themeData.cardColor;
    var boxDecoration = BoxDecoration(
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

    if (widget.aId != null) {
      return Selector<ReplaceableEventProvider, Event?>(
        builder: (context, event, child) {
          if (event == null) {
            return buildBlankWidget(boxDecoration);
          }

          return buildEventWidget(event, cardColor, boxDecoration);
        },
        selector: (context, provider) {
          return provider.getEvent(widget.aId!);
        },
      );
    }

    return FutureBuilder(
      future: this.eventFuture,
      initialData: null,
      builder: (context, as) {
        if (as.data == null) {
          return buildBlankWidget(boxDecoration);
        }
        return buildEventWidget(as.data!, cardColor, boxDecoration);
      },
    );
  }

  Widget buildEventWidget(
      Event event, Color cardColor, BoxDecoration boxDecoration) {
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

  Widget buildBlankWidget(BoxDecoration boxDecoration) {
    return Container(
      margin: const EdgeInsets.all(Base.BASE_PADDING),
      height: 60,
      decoration: boxDecoration,
      child: const Center(child: Text("Note loading")),
    );
  }

  void jumpToThread(Event event) {
    RouterUtil.router(context, RouterPath.THREAD_DETAIL, event);
  }
}
