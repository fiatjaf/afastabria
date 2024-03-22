import "package:bot_toast/bot_toast.dart";
import "package:convert/convert.dart";
import "package:flutter/material.dart";
import "package:loure/component/content/content_component.dart";
import "package:provider/provider.dart";

import "package:loure/client/event.dart";
import "package:loure/client/nip69/poll_info.dart";
import "package:loure/client/zap/zap_action.dart";
import "package:loure/client/zap/zap_num_util.dart";
import "package:loure/consts/base.dart";
import "package:loure/data/event_reactions.dart";
import "package:loure/main.dart";
import "package:loure/provider/event_reactions_provider.dart";
import "package:loure/util/number_format_util.dart";
import "package:loure/util/spider_util.dart";
import "package:loure/util/string_util.dart";
import "package:loure/component/editor/text_input_dialog.dart";

// ignore: must_be_immutable
class EventPollComponent extends StatefulWidget {
  EventPollComponent({required this.event, super.key});
  Event event;

  @override
  State<StatefulWidget> createState() {
    return _EventPollComponent();
  }
}

class _EventPollComponent extends State<EventPollComponent> {
  PollInfo? pollInfo;

  @override
  Widget build(final BuildContext context) {
    final themeData = Theme.of(context);
    final hintColor = themeData.hintColor;
    final pollBackgroundColor = hintColor.withOpacity(0.3);
    final mainColor = themeData.primaryColor;
    // log(jsonEncode(widget.event.toJson()));

    return Selector<EventReactionsProvider, EventReactions?>(
      builder: (final context, final eventReactions, final child) {
        // count the poll number.
        int total = 0;
        Map<String, int> pollNums = {};
        var myNum = 0;
        if (eventReactions != null) {
          for (final zapEvent in eventReactions.zaps) {
            int num = 0;
            String? selectKey;
            String? senderPubkey;

            for (final tag in zapEvent.tags) {
              if (tag.length > 1) {
                final tagType = tag[0];
                if (tagType == "bolt11") {
                  final zapStr = tag[1];
                  num = ZapNumUtil.getNumFromStr(zapStr);
                } else if (tagType == "description") {
                  final text = tag[1];
                  selectKey =
                      SpiderUtil.subUntil(text, "[\"poll_option\",\"", "\"");
                  senderPubkey = SpiderUtil.subUntil(text, "pubkey\":\"", "\"");
                }
              }
            }

            // print("selectKey $selectKey num $num");
            if (num > 0 && StringUtil.isNotBlank(selectKey)) {
              total += num;

              if (senderPubkey == nostr.publicKey) {
                myNum += num;
              }

              var pollOptionNum = pollNums[selectKey];
              pollOptionNum ??= 0;
              pollOptionNum += num;
              pollNums[selectKey!] = pollOptionNum;
            }
          }
        }

        List<Widget> list = [];

        pollInfo = PollInfo.fromEvent(widget.event);

        if (StringUtil.isNotBlank(pollInfo!.consensusThreshold) &&
            pollInfo!.consensusThreshold != "null") {
          list.add(
            Text(pollInfo!.consensusThreshold!),
          );
        }

        if (pollInfo!.closedAt != null) {
          final closeAtDT =
              DateTime.fromMillisecondsSinceEpoch(pollInfo!.closedAt!);
          final format = FixedDateTimeFormatter("YYYY-MM-DD hh:mm:ss");
          list.add(Row(
            children: [Text("Close at ${format.encode(closeAtDT)}")],
          ));
        }

        if (myNum > 0) {
          final myNumStr = NumberFormatUtil.format(myNum);
          list.add(
            Text("${"You had voted with"} $myNumStr sats."),
          );
        }

        List<Widget> pollList = [];
        for (final pollOption in pollInfo!.pollOptions) {
          final String selectKey = pollOption[0];
          double percent = 0;

          var num = pollNums[selectKey];
          if (num != null && total > 0) {
            percent = num / total;
          }
          num ??= 0;
          // print("percent $percent");

          final pollItemWidget = Container(
            width: double.maxFinite,
            margin: const EdgeInsets.only(
              top: Base.BASE_PADDING_HALF,
            ),
            decoration: BoxDecoration(
              color: pollBackgroundColor,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(Base.BASE_PADDING_HALF),
                  width: double.maxFinite,
                  child: AbsorbPointer(
                    child: ContentComponent(
                      content: pollOption[1],
                      event: widget.event,
                    ),
                    // child: Column(
                    //   mainAxisSize: MainAxisSize.min,
                    //   crossAxisAlignment: CrossAxisAlignment.start,
                    //   children: ContentDecoder.decode(
                    //       context, pollOption[1], widget.event),
                    // ),
                  ),
                ),
                Positioned.fill(
                  child: Container(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      heightFactor: 1,
                      widthFactor: percent,
                      child: Container(
                        decoration: BoxDecoration(
                          color: mainColor.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: Base.BASE_PADDING,
                  child: Text(
                    "${(percent * 100).toStringAsFixed(2)}% ${NumberFormatUtil.format(num)} sats",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );

          pollList.add(GestureDetector(
            onTap: () {
              tapZap(selectKey);
            },
            child: pollItemWidget,
          ));
        }
        list.add(
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: pollList,
          ),
        );

        if (pollInfo!.valueMinimum != null && pollInfo!.valueMaximum != null) {
          list.add(Container(
            margin: const EdgeInsets.only(top: Base.BASE_PADDING_HALF),
            child: Text(
              "${"min zap num"}: ${pollInfo!.valueMinimum}  ${"max zap num"}: ${pollInfo!.valueMaximum}",
              style: TextStyle(
                color: hintColor,
              ),
            ),
          ));
        }

        return Container(
          // color: Colors.red,
          width: double.maxFinite,
          margin: const EdgeInsets.only(
            top: Base.BASE_PADDING_HALF,
            bottom: Base.BASE_PADDING_HALF,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: list,
          ),
        );
      },
      selector: (final context, final provider_) {
        return provider_.get(widget.event.id);
      },
    );
  }

  Future<void> tapZap(final String selectKey) async {
    final numStr = await TextInputDialog.show(context, "Input Sats num",
        valueCheck: inputCheck);
    if (numStr != null) {
      final num = int.tryParse(numStr);
      if (num != null) {
        ZapAction.handleZap(
          context,
          num,
          widget.event.pubkey,
          eventId: widget.event.id,
          pollOption: selectKey,
        );
      }
    }
  }

  bool inputCheck(final BuildContext context, final String value) {
    if (StringUtil.isBlank(value)) {
      BotToast.showText(text: "Input_can_not_be_null");
      return false;
    }

    final num = int.tryParse(value);
    if (num == null) {
      BotToast.showText(text: "Input_parse_error");
      return false;
    } else {
      if (pollInfo != null &&
          pollInfo!.valueMinimum != null &&
          pollInfo!.valueMinimum! > num) {
        BotToast.showText(
            text:
                "${"Zap_num_can_not_smaller_then"} ${pollInfo!.valueMinimum!}");
        return false;
      }
      if (pollInfo != null &&
          pollInfo!.valueMaximum != null &&
          pollInfo!.valueMaximum! < num) {
        BotToast.showText(
            text:
                "${"Zap_num_can_not_bigger_then"} ${pollInfo!.valueMaximum!}");
        return false;
      }
    }

    return true;
  }
}
