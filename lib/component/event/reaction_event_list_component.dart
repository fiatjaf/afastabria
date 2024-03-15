import 'package:flutter/material.dart';

import 'package:loure/client/event.dart';
import 'package:loure/consts/base.dart';
import 'package:loure/consts/router_path.dart';
import 'package:loure/util/router_util.dart';
import 'package:loure/component/event/reaction_event_item_component.dart';

class ReactionEventListComponent extends StatefulWidget {
  Event event;

  bool jumpable;

  String text;

  ReactionEventListComponent({super.key, 
    required this.event,
    this.jumpable = true,
    required this.text,
  });

  @override
  State<StatefulWidget> createState() => _ReactionEventListComponent();
}

class _ReactionEventListComponent extends State<ReactionEventListComponent> {
  @override
  Widget build(BuildContext context) {
    var themeData = Theme.of(context);
    var cardColor = themeData.cardColor;

    var main = Container(
      color: cardColor,
      margin: const EdgeInsets.only(bottom: Base.BASE_PADDING_HALF),
      padding: const EdgeInsets.only(
        top: Base.BASE_PADDING,
        bottom: Base.BASE_PADDING,
      ),
      child: ReactionEventItemComponent(
        pubkey: widget.event.pubKey,
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
