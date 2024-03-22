import "package:convert/convert.dart";
import "package:flutter/material.dart";
import "package:loure/client/nip75/zap_goals_info.dart";
import "package:loure/util/string_util.dart";
import "package:provider/provider.dart";

import "package:loure/client/event.dart";
import "package:loure/consts/base.dart";
import "package:loure/data/event_reactions.dart";
import "package:loure/provider/event_reactions_provider.dart";
import "package:loure/util/number_format_util.dart";
import "package:loure/component/event/event_quote_component.dart";

class EventZapGoalsComponent extends StatefulWidget {
  EventZapGoalsComponent({required this.event, super.key});
  Event event;

  @override
  State<StatefulWidget> createState() {
    return _EventZapGoalsComponent();
  }
}

class _EventZapGoalsComponent extends State<EventZapGoalsComponent> {
  ZapGoalsInfo? zapGoalsInfo;

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
        int zapNum = 0;
        if (eventReactions != null) {
          zapNum = eventReactions.zapNum;
        }

        List<Widget> list = [];

        zapGoalsInfo = ZapGoalsInfo.fromEvent(widget.event);
        if (zapGoalsInfo!.amount == 0) {
          return Container();
        }

        if (zapGoalsInfo!.closedAt != null) {
          final closeAtDT =
              DateTime.fromMillisecondsSinceEpoch(zapGoalsInfo!.closedAt!);
          final format = FixedDateTimeFormatter("YYYY-MM-DD hh:mm:ss");
          list.add(Row(
            children: [Text("${"Close at"} ${format.encode(closeAtDT)}")],
          ));
        }

        final double percent = zapNum / zapGoalsInfo!.amount!;

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
                child: Row(children: [
                  const Icon(Icons.bolt),
                  Expanded(child: Container()),
                ]),
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
                  "${(percent * 100).toStringAsFixed(2)}%  ${NumberFormatUtil.format(zapNum)}/${NumberFormatUtil.format(zapGoalsInfo!.amount!)} sats",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );

        list.add(GestureDetector(
          onTap: () {
            // tapZap(selectKey);
          },
          child: pollItemWidget,
        ));

        if (StringUtil.isNotBlank(zapGoalsInfo!.goal)) {
          list.add(EventQuoteComponent(
            id: zapGoalsInfo!.goal,
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
      selector: (final context, final provider) {
        return provider.get(widget.event.id);
      },
    );
  }

  Future<void> tapZap(final String selectKey) async {
    // var numStr = await TextInputDialog.show(
    //     context, "Input_Sats_num",
    //     valueCheck: inputCheck);
    // if (numStr != null) {
    //   var num = int.tryParse(numStr);
    //   if (num != null) {
    //     ZapAction.handleZap(
    //       context,
    //       num,
    //       widget.event.pubkey,
    //       eventId: widget.event.id,
    //       pollOption: selectKey,
    //     );
    //   }
    // }
  }
}
