import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:nostrmo/client/relay/relay.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/router/relays/relays_item_component.dart';

import 'package:nostrmo/util/when_stop_function.dart';

import 'package:nostrmo/component/cust_state.dart';
import 'package:nostrmo/consts/base.dart';
import 'package:nostrmo/util/router_util.dart';
import 'package:nostrmo/util/string_util.dart';

class RelaysRouter extends StatefulWidget {
  const RelaysRouter({super.key});

  @override
  State<StatefulWidget> createState() {
    return _RelaysRouter();
  }
}

class _RelaysRouter extends CustState<RelaysRouter> with WhenStopFunction {
  TextEditingController controller = TextEditingController();
  @override
  Widget doBuild(BuildContext context) {
    var themeData = Theme.of(context);
    // var color = themeData.textTheme.bodyLarge!.color;
    var titleFontSize = themeData.textTheme.bodyLarge!.fontSize;

    return Scaffold(
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () {
            RouterUtil.back(context);
          },
          child: Icon(
            Icons.arrow_back_ios,
            color: themeData.appBarTheme.titleTextStyle!.color,
          ),
        ),
        title: Text(
          "[relays]",
          style: TextStyle(
            fontSize: titleFontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(children: [
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(
              top: Base.BASE_PADDING,
            ),
            child: ListView.builder(
              itemBuilder: (context, index) {
                var addr = nostr.relayList.all[index];
                var relayStatus = nostr.pool.getRelayStatus(addr);
                relayStatus ??= RelayStatus(addr);
                return RelaysItemComponent(
                  addr: addr,
                  relayStatus: relayStatus,
                );
              },
              itemCount: nostr.relayList.all.length,
            ),
          ),
        ),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.cloud),
            hintText: "Input relay address.",
            suffixIcon: IconButton(
              icon: const Icon(Icons.add),
              onPressed: addRelay,
            ),
          ),
        ),
      ]),
    );
  }

  void addRelay() {
    var addr = controller.text;
    addr = addr.trim();
    if (StringUtil.isBlank(addr)) {
      BotToast.showText(text: "Address can't be null");
      return;
    }

    // relayProvider.addRelay(addr);
    controller.clear();
    FocusScope.of(context).unfocus();
  }

  // Event? remoteRelayEvent;

  @override
  Future<void> onReady(BuildContext context) async {
    // var filter = Filter(
    //     authors: [nostr!.publicKey],
    //     limit: 1,
    //     kinds: [kind.EventKind.RELAY_LIST_METADATA]);
    // nostr!.query([filter.toJson()], (event) {
    //   if ((remoteRelayEvent != null &&
    //           event.createdAt > remoteRelayEvent!.createdAt) ||
    //       remoteRelayEvent == null) {
    //     setState(() {
    //       remoteRelayEvent = event;
    //     });
    //     whenStop(handleRemoteRelays);
    //   }
    // });
  }

  // Future<void> handleRemoteRelays() async {
  // var relaysUpdatedTime = relayProvider.updatedTime();
  // if (remoteRelayEvent != null &&
  //     (relaysUpdatedTime == null ||
  //         remoteRelayEvent!.createdAt - relaysUpdatedTime > 60 * 5)) {
  //   var result = await ConfirmDialog.show(context,
  //       "Find_clouded_relay_list_do_you_want_to_download");
  //   if (result == true) {
  //     List<String> list = [];
  //     for (var tag in remoteRelayEvent!.tags) {
  //       if (tag.length > 1) {
  //         var key = tag[0];
  //         var value = tag[1];
  //         if (key == "r") {
  //           list.add(value);
  //         }
  //       }
  //     }
  //     relayProvider.setRelayListAndUpdate(list);
  //   }
  // }
  // }
}
