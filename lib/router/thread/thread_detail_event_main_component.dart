import "package:flutter/material.dart";
import "package:loure/component/event/event_main_component.dart";
import "package:loure/main.dart";
import "package:loure/router/thread/thread_detail_event.dart";
import "package:screenshot/screenshot.dart";

import "package:loure/consts/base.dart";

class ThreadDetailItemMainComponent extends StatefulWidget {
  ThreadDetailItemMainComponent({
    required this.item,
    required this.totalMaxWidth,
    required this.sourceEventId,
    required this.sourceEventKey,
    super.key,
  });
  static double BORDER_LEFT_WIDTH = 2;

  static double EVENT_MAIN_MIN_WIDTH = 200;

  ThreadDetailEvent item;

  double totalMaxWidth;

  String sourceEventId;

  GlobalKey sourceEventKey;

  @override
  State<StatefulWidget> createState() {
    return _ThreadDetailItemMainComponent();
  }
}

class _ThreadDetailItemMainComponent
    extends State<ThreadDetailItemMainComponent> {
  ScreenshotController screenshotController = ScreenshotController();

  @override
  Widget build(final BuildContext context) {
    final themeData = Theme.of(context);
    final hintColor = themeData.hintColor;
    final cardColor = themeData.cardColor;

    final currentMainEvent = EventMainComponent(
      screenshotController: screenshotController,
      event: widget.item.event,
      showReplying: false,
      showVideo: true,
      imageListMode: false,
      showSubject: false,
      showLinkedLongForm: false,
    );

    List<Widget> list = [];
    var currentWidth = mediaDataCache.size.width;
    final leftWidth = (widget.item.currentLevel - 1) *
        (Base.BASE_PADDING + ThreadDetailItemMainComponent.BORDER_LEFT_WIDTH);
    currentWidth = mediaDataCache.size.width - leftWidth;
    if (currentWidth < ThreadDetailItemMainComponent.EVENT_MAIN_MIN_WIDTH) {
      currentWidth = ThreadDetailItemMainComponent.EVENT_MAIN_MIN_WIDTH;
    }
    list.add(Container(
      alignment: Alignment.centerLeft,
      width: currentWidth,
      child: currentMainEvent,
    ));

    if (widget.item.subItems.isNotEmpty) {
      List<Widget> subWidgets = [];
      for (final subItem in widget.item.subItems) {
        subWidgets.add(
          Container(
            child: ThreadDetailItemMainComponent(
              item: subItem,
              totalMaxWidth: widget.totalMaxWidth,
              sourceEventId: widget.sourceEventId,
              sourceEventKey: widget.sourceEventKey,
            ),
          ),
        );
      }
      list.add(Container(
        alignment: Alignment.centerLeft,
        margin: const EdgeInsets.only(
          // top: Base.BASE_PADDING,
          bottom: Base.BASE_PADDING,
          left: Base.BASE_PADDING,
        ),
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              width: ThreadDetailItemMainComponent.BORDER_LEFT_WIDTH,
              color: hintColor,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: subWidgets,
        ),
      ));
    }

    Key? currentEventKey;
    if (widget.item.event.id == widget.sourceEventId) {
      currentEventKey = widget.sourceEventKey;
    }

    return Screenshot(
      controller: screenshotController,
      child: Container(
        key: currentEventKey,
        padding: const EdgeInsets.only(
          top: Base.BASE_PADDING,
        ),
        color: cardColor,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: list,
        ),
      ),
    );
  }
}
