import 'package:convert/convert.dart';
import 'package:flutter/material.dart';
import 'package:nostrmo/client/nip75/zap_goals_info.dart';
import 'package:nostrmo/util/string_util.dart';
import 'package:provider/provider.dart';

import 'package:nostrmo/client/event.dart';
import 'package:nostrmo/consts/base.dart';
import 'package:nostrmo/data/event_reactions.dart';
import 'package:nostrmo/provider/event_reactions_provider.dart';
import 'package:nostrmo/util/number_format_util.dart';
import 'package:nostrmo/component/event/event_quote_component.dart';

class EventZapGoalsComponent extends StatefulWidget {
  Event event;

  EventZapGoalsComponent({super.key, required this.event});

  @override
  State<StatefulWidget> createState() {
    return _EventZapGoalsComponent();
  }
}

class _EventZapGoalsComponent extends State<EventZapGoalsComponent> {
  ZapGoalsInfo? zapGoalsInfo;

  @override
  Widget build(BuildContext context) {
        var themeData = Theme.of(context);
    var hintColor = themeData.hintColor;
    var pollBackgroundColor = hintColor.withOpacity(0.3);
    var mainColor = themeData.primaryColor;
    // log(jsonEncode(widget.event.toJson()));

    return Selector<EventReactionsProvider, EventReactions?>(
      builder: (context, eventReactions, child) {
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
          var closeAtDT =
              DateTime.fromMillisecondsSinceEpoch(zapGoalsInfo!.closedAt!);
          var format = FixedDateTimeFormatter("YYYY-MM-DD hh:mm:ss");
          list.add(Row(
            children: [Text("${"Close at"} ${format.encode(closeAtDT)}")],
          ));
        }

        double percent = zapNum / zapGoalsInfo!.amount!;

        var pollItemWidget = Container(
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
      selector: (context, provider) {
        return provider.get(widget.event.id);
      },
    );
  }

  Future<void> tapZap(String selectKey) async {
    // var numStr = await TextInputDialog.show(
    //     context, "Input_Sats_num",
    //     valueCheck: inputCheck);
    // if (numStr != null) {
    //   var num = int.tryParse(numStr);
    //   if (num != null) {
    //     ZapAction.handleZap(
    //       context,
    //       num,
    //       widget.event.pubKey,
    //       eventId: widget.event.id,
    //       pollOption: selectKey,
    //     );
    //   }
    // }
  }
}
