import "dart:convert";

import "package:flutter/material.dart";

import "package:loure/client/event.dart";
import "package:loure/client/zap/zap_num_util.dart";
import "package:loure/util/number_format_util.dart";
import "package:loure/util/spider_util.dart";
import "package:loure/util/string_util.dart";
import "package:loure/component/event/reaction_event_item_component.dart";

// ignore: must_be_immutable
class ZapEventMainComponent extends StatefulWidget {
  ZapEventMainComponent({required this.event, super.key});
  Event event;

  @override
  State<StatefulWidget> createState() {
    return _ZapEventMainComponent();
  }
}

class _ZapEventMainComponent extends State<ZapEventMainComponent> {
  String? senderPubkey;
  late String eventId;

  @override
  void initState() {
    super.initState();

    eventId = widget.event.id;
    parseSenderPubkey();
  }

  void parseSenderPubkey() {
    String? zapRequestEventStr;
    for (final tag in widget.event.tags) {
      if (tag.length > 1) {
        final key = tag[0];
        if (key == "description") {
          zapRequestEventStr = tag[1];
        }
      }
    }

    if (StringUtil.isNotBlank(zapRequestEventStr)) {
      try {
        final eventJson = jsonDecode(zapRequestEventStr!);
        final zapRequestEvent = Event.fromJson(eventJson);
        senderPubkey = zapRequestEvent.pubkey;
      } catch (e) {
        print("jsonDecode zapRequest error ${e.toString()}");
        senderPubkey =
            SpiderUtil.subUntil(zapRequestEventStr!, "pubkey\":\"", "\"");
      }
    }
  }

  @override
  Widget build(final BuildContext context) {
    if (StringUtil.isBlank(senderPubkey)) {
      return Container();
    }

    if (eventId != widget.event.id) {
      parseSenderPubkey();
    }

    final zapNum = ZapNumUtil.getNumFromZapEvent(widget.event);
    final String zapNumStr = NumberFormatUtil.format(zapNum);

    final text = "zaped $zapNumStr sats";

    return ReactionEventItemComponent(
        pubkey: senderPubkey!, text: text, createdAt: widget.event.createdAt);
  }
}
