import "package:flutter/material.dart";

import "package:loure/client/event_kind.dart" as kind;
import "package:loure/component/event/event_bitcion_icon_component.dart";
import "package:loure/consts/base.dart";
import "package:loure/router/thread/thread_detail_event.dart";
import "package:loure/router/thread/thread_detail_event_main_component.dart";

class ThreadDetailItemComponent extends StatefulWidget {
  ThreadDetailItemComponent({
    required this.item,
    required this.totalMaxWidth,
    required this.sourceEventId,
    required this.sourceEventKey,
    super.key,
  });
  double totalMaxWidth;

  ThreadDetailEvent item;

  String sourceEventId;

  GlobalKey sourceEventKey;

  @override
  State<StatefulWidget> createState() {
    return _ThreadDetailItemComponent();
  }
}

class _ThreadDetailItemComponent extends State<ThreadDetailItemComponent> {
  @override
  Widget build(final BuildContext context) {
    final themeData = Theme.of(context);
    final cardColor = themeData.cardColor;
    final hintColor = themeData.hintColor;

    Widget main = ThreadDetailItemMainComponent(
      item: widget.item,
      totalMaxWidth: widget.totalMaxWidth,
      sourceEventId: widget.sourceEventId,
      sourceEventKey: widget.sourceEventKey,
    );

    if (widget.item.event.kind == kind.EventKind.ZAP) {
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

    return Container(
      color: cardColor,
      margin: const EdgeInsets.only(bottom: Base.BASE_PADDING_HALF),
      child: main,
    );
  }
}
