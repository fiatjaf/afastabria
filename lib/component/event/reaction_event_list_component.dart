import "package:flutter/material.dart";

import "package:loure/client/event.dart";
import "package:loure/consts/base.dart";
import "package:loure/router/routes.dart";
import "package:loure/util/router_util.dart";
import "package:loure/component/event/reaction_event_item_component.dart";

class ReactionEventListComponent extends StatefulWidget {
  ReactionEventListComponent({
    required this.event,
    required this.text,
    super.key,
    this.jumpable = true,
  });
  Event event;

  bool jumpable;

  String text;

  @override
  State<StatefulWidget> createState() => _ReactionEventListComponent();
}

class _ReactionEventListComponent extends State<ReactionEventListComponent> {
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
      child: ReactionEventItemComponent(
        pubkey: widget.event.pubkey,
        text: widget.text,
        createdAt: widget.event.createdAt,
      ),
    );

    if (widget.jumpable) {
      return GestureDetector(
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
