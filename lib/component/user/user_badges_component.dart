import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:nostrmo/client/event_kind.dart' as kind;
import 'package:nostrmo/client/filter.dart';
import 'package:nostrmo/client/nip58/badge_definition.dart';
import 'package:nostrmo/consts/base.dart';
import 'package:nostrmo/data/event_mem_box.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/provider/badge_definition_provider.dart';
import 'package:nostrmo/util/later_function.dart';
import 'package:nostrmo/component/badge_component.dart';
import 'package:nostrmo/component/badge_detail_dialog.dart';
import 'package:nostrmo/component/cust_state.dart';

// ignore: must_be_immutable
class UserBadgesComponent extends StatefulWidget {
  String pubkey;

  UserBadgesComponent({super.key, required this.pubkey});

  @override
  State<StatefulWidget> createState() {
    return _UserBadgesComponent();
  }
}

class _UserBadgesComponent extends CustState<UserBadgesComponent>
    with LaterFunction {
  @override
  Widget doBuild(BuildContext context) {
    if (eventMemBox.isEmpty()) {
      return Container();
    }

    List<Widget> list = [];

    Map<dynamic, int> existMap = {};

    var events = eventMemBox.all();
    for (var event in events) {
      for (var tag in event.tags) {
        if (tag.length > 1) {
          if (tag[0] == "a") {
            var badgeId = tag[1];
            var itemWidget =
                Selector<BadgeDefinitionProvider, BadgeDefinition?>(
                    builder: (context, badgeDefinition, child) {
              if (badgeDefinition == null) {
                return Container();
              }

              if (existMap[badgeId] != null) {
                return Container();
              }
              existMap[badgeId] = 1;

              return GestureDetector(
                onTap: () {
                  BadgeDetailDialog.show(context, badgeDefinition);
                },
                child: Container(
                  margin: const EdgeInsets.only(right: Base.BASE_PADDING_HALF),
                  child: BedgeComponent(
                    badgeDefinition: badgeDefinition,
                  ),
                ),
              );
            }, selector: (context, provider) {
              return provider.get(badgeId, event.pubKey);
            });

            list.add(itemWidget);
            break;
          }
        }
      }
    }

    return Container(
      padding: const EdgeInsets.only(
        right: Base.BASE_PADDING,
        left: Base.BASE_PADDING,
      ),
      width: double.maxFinite,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: list,
        ),
      ),
    );
  }

  EventMemBox eventMemBox = EventMemBox(sortAfterAdd: false);

  @override
  Future<void> onReady(BuildContext context) async {
    nostr.pool.querySingle(
        ["wss://relay.nostr.band"],
        Filter(
            authors: [widget.pubkey],
            kinds: [kind.EventKind.BADGE_ACCEPT])).then((event) {
      if (event == null) return;

      var result = eventMemBox.add(event);
      if (result) {
        later(() {
          setState(() {});
        }, null);
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    disposeLater();
  }
}
