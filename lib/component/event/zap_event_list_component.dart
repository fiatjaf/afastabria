import "package:flutter/material.dart";

import "package:loure/client/event.dart";
import "package:loure/consts/base.dart";
import "package:loure/consts/router_path.dart";
import "package:loure/util/router_util.dart";
import "package:loure/component/event/zap_event_main_component.dart";

class ZapEventListComponent extends StatefulWidget {
  ZapEventListComponent({
    required this.event,
    super.key,
    this.jumpable = true,
  });
  Event event;

  bool jumpable;

  @override
  State<StatefulWidget> createState() {
    return _ZapEventListComponent();
  }
}

class _ZapEventListComponent extends State<ZapEventListComponent> {
  @override
  Widget build(final BuildContext context) {
    final themeData = Theme.of(context);
    final cardColor = themeData.cardColor;

    final main = Container(
      color: cardColor,
      margin: const EdgeInsets.only(bottom: Base.BASE_PADDING_HALF),
      padding: const EdgeInsets.only(
        top: Base.BASE_PADDING,
        bottom: Base.BASE_PADDING,
      ),
      child: ZapEventMainComponent(
        event: widget.event,
      ),
    );

    if (widget.jumpable) {
      return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: jumpToThread,
        child: main,
      );
    } else {
      return main;
    }
  }

  void jumpToThread() {
    RouterUtil.router(context, RouterPath.THREAD_DETAIL, widget.event);
  }
}
