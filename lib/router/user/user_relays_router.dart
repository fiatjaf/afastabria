import 'package:flutter/material.dart';


import 'package:nostrmo/client/relay/relay_metadata.dart';
import 'package:nostrmo/consts/base.dart';
import 'package:nostrmo/util/router_util.dart';

class UserRelayRouter extends StatefulWidget {
  const UserRelayRouter({super.key});

  @override
  State<StatefulWidget> createState() {
    return _UserRelayRouter();
  }
}

class _UserRelayRouter extends State<UserRelayRouter> {
  List<RelayMetadata>? relays;
  @override
  Widget build(BuildContext context) {
    var themeData = Theme.of(context);

    if (relays == null) {
      relays = [];
      var arg = RouterUtil.routerArgs(context);
      if (arg != null && arg is List<dynamic>) {
        for (var tag in arg) {
          if (tag is List<dynamic>) {
            var length = tag.length;
            bool write = true;
            bool read = true;
            if (length > 1) {
              var name = tag[0];
              var value = tag[1];
              if (name == "r") {
                if (length > 2) {
                  var operType = tag[2];
                  if (operType == "read") {
                    write = false;
                  } else if (operType == "write") {
                    read = false;
                  }
                }

                relays!.add(RelayMetadata(value, read, write));
              }
            }
          }
        }
      }
    }

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
        title: const Text("Relays"),
      ),
      body: Container(
        margin: const EdgeInsets.only(
          top: Base.BASE_PADDING,
        ),
        child: const Text("[relay status should go here]"),
        // child: ListView.builder(
        //   itemBuilder: (context, index) {
        //     var relayMetadata = relays![index];
        //     return Selector<RelayProvider, RelayStatus?>(
        //         builder: (context, relayStatus, child) {
        //       return RelayMetadataComponent(
        //         relayMetadata: relayMetadata,
        //         addAble: relayStatus == null,
        //       );
        //     }, selector: (context, provider) {
        //       return provider.getRelayStatus(relayMetadata.addr);
        //     });
        //   },
        //   itemCount: relays!.length,
        // ),
      ),
    );
  }
}

// ignore: must_be_immutable
class RelayMetadataComponent extends StatelessWidget {
  RelayMetadata relayMetadata;

  bool addAble;

  RelayMetadataComponent(
      {super.key, required this.relayMetadata, this.addAble = true});

  @override
  Widget build(BuildContext context) {
    var themeData = Theme.of(context);
    var cardColor = themeData.cardColor;
    var hintColor = themeData.hintColor;
    var bodySmallFontSize = themeData.textTheme.bodySmall!.fontSize;

    Widget rightBtn = Container();
    if (addAble) {
      rightBtn = GestureDetector(
        onTap: () {
          nostr.addRelay(relayMetadata.addr);
        },
        child: const Icon(
          Icons.add,
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(
        bottom: Base.BASE_PADDING,
        left: Base.BASE_PADDING,
        right: Base.BASE_PADDING,
      ),
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Container(
        padding: const EdgeInsets.only(
          top: Base.BASE_PADDING_HALF,
          bottom: Base.BASE_PADDING_HALF,
          left: Base.BASE_PADDING,
          right: Base.BASE_PADDING,
        ),
        decoration: BoxDecoration(
          color: cardColor,
          border: Border(
            left: BorderSide(
              width: 6,
              color: hintColor,
            ),
          ),
          // borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(bottom: 2),
                    child: Text(relayMetadata.addr),
                  ),
                  Row(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(right: Base.BASE_PADDING),
                        child: Text(
                          "Read",
                          style: TextStyle(
                            fontSize: bodySmallFontSize,
                            color:
                                relayMetadata.read ? Colors.green : Colors.red,
                          ),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(right: Base.BASE_PADDING),
                        child: Text(
                          "Write",
                          style: TextStyle(
                            fontSize: bodySmallFontSize,
                            color:
                                relayMetadata.write ? Colors.green : Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            rightBtn,
          ],
        ),
      ),
    );
  }
}
