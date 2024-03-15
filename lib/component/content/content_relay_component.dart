import 'package:flutter/material.dart';
import 'package:nostrmo/main.dart';
import 'package:provider/provider.dart';

import 'package:nostrmo/client/relay/relay_pool.dart';
import 'package:nostrmo/component/confirm_dialog.dart';
import 'package:nostrmo/client/relay/relay.dart';
import 'package:nostrmo/consts/base.dart';

// ignore: must_be_immutable
class ContentRelayComponent extends StatelessWidget {
  String addr;

  ContentRelayComponent(this.addr, {super.key});

  @override
  Widget build(BuildContext context) {
    var themeData = Theme.of(context);
    Color? cardColor = themeData.cardColor;
    if (cardColor == Colors.white) {
      cardColor = Colors.grey[300];
    }
    var fontSize = themeData.textTheme.bodyMedium!.fontSize;

    return Selector<RelayPool, RelayStatus?>(
        builder: (context, relayStatus, client) {
      List<Widget> list = [
        Icon(
          Icons.cloud,
          size: fontSize,
        ),
        Container(
          margin: const EdgeInsets.only(
            left: 6,
            right: 4,
          ),
          child: Text(addr),
        )
      ];
      if (relayStatus == null) {
        list.add(Icon(
          Icons.add,
          size: fontSize,
        ));
      }

      Widget main = Container(
        padding: const EdgeInsets.only(
          left: Base.BASE_PADDING_HALF,
          right: Base.BASE_PADDING_HALF,
          top: 2,
          bottom: 2,
        ),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: list,
        ),
      );

      if (relayStatus == null) {
        main = GestureDetector(
          onTap: () async {
            var result =
                await ConfirmDialog.show(context, "Add this relay to local");
            if (result == true) {
              nostr.relayList.add(addr, true, true);
            }
          },
          child: main,
        );
      }

      return main;
    }, selector: (context, provider) {
      return provider.getRelayStatus(addr);
    });
  }
}
