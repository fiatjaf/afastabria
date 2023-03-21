import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:nostr_dart/nostr_dart.dart';
import 'package:provider/provider.dart';

import '../../client/event_relation.dart';
import '../../client/nip19/nip19.dart';
import '../../consts/base.dart';
import '../../consts/router_path.dart';
import '../../data/metadata.dart';
import '../../provider/metadata_provider.dart';
import '../../util/router_util.dart';
import '../../util/string_util.dart';
import 'event_top_component.dart';

class EventMainComponent extends StatefulWidget {
  Event event;

  String? pagePubkey;

  bool showReplying;

  EventMainComponent({
    required this.event,
    this.pagePubkey,
    this.showReplying = true,
  });

  @override
  State<StatefulWidget> createState() {
    return _EventMainComponent();
  }
}

class _EventMainComponent extends State<EventMainComponent> {
  late EventRelation eventRelation;

  @override
  void initState() {
    super.initState();
    eventRelation = EventRelation.fromEvent(widget.event);
  }

  @override
  Widget build(BuildContext context) {
    var themeData = Theme.of(context);
    var hintColor = themeData.hintColor;
    var smallTextSize = themeData.textTheme.bodySmall!.fontSize;

    List<Widget> list = [];
    if (widget.showReplying && eventRelation.tagPList.isNotEmpty) {
      var textStyle = TextStyle(
        color: hintColor,
        fontSize: smallTextSize,
      );
      List<Widget> replyingList = [];
      var length = eventRelation.tagPList.length;
      replyingList.add(Text(
        "Replying: ",
        style: textStyle,
      ));
      for (var index = 0; index < length; index++) {
        var p = eventRelation.tagPList[index];
        var isLast = index < length - 1 ? false : true;
        replyingList.add(EventReplyingcomponent(pubkey: p));
        if (!isLast) {
          replyingList.add(Text(
            " & ",
            style: textStyle,
          ));
        }
      }
      list.add(Container(
        width: double.maxFinite,
        padding: EdgeInsets.only(
          bottom: Base.BASE_PADDING_HALF,
        ),
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: replyingList,
        ),
      ));
    }
    list.add(Container(
      width: double.maxFinite,
      child: Text(widget.event.content),
    ));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        EventTopComponent(
          event: widget.event,
          pagePubkey: widget.pagePubkey,
        ),
        Container(
          width: double.maxFinite,
          padding: const EdgeInsets.only(
            left: Base.BASE_PADDING,
            right: Base.BASE_PADDING,
          ),
          child: Column(
            children: list,
            mainAxisSize: MainAxisSize.min,
          ),
        ),
      ],
    );
  }
}

class EventReplyingcomponent extends StatefulWidget {
  String pubkey;

  EventReplyingcomponent({required this.pubkey});

  @override
  State<StatefulWidget> createState() {
    return _EventReplyingcomponent();
  }
}

class _EventReplyingcomponent extends State<EventReplyingcomponent> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        RouterUtil.router(context, RouterPath.USER, widget.pubkey);
      },
      child: Selector<MetadataProvider, Metadata?>(
        builder: (context, metadata, child) {
          var themeData = Theme.of(context);
          var hintColor = themeData.hintColor;
          var smallTextSize = themeData.textTheme.bodySmall!.fontSize;
          String nip19Name = Nip19.encodeSimplePubKey(widget.pubkey);
          String displayName = nip19Name;
          String name = "";

          Widget? imageWidget;
          if (metadata != null) {
            if (StringUtil.isNotBlank(metadata.displayName)) {
              displayName = metadata.displayName!;
            }
          }

          return Text(
            displayName,
            style: TextStyle(
              color: hintColor,
              fontSize: smallTextSize,
              // fontWeight: FontWeight.bold,
            ),
          );
        },
        selector: (context, _provider) {
          return _provider.getMetadata(widget.pubkey);
        },
      ),
    );
  }
}