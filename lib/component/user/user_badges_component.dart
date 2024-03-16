import "package:flutter/material.dart";
import "package:provider/provider.dart";

import "package:loure/client/event_kind.dart" as kind;
import "package:loure/client/filter.dart";
import "package:loure/client/nip58/badge_definition.dart";
import "package:loure/consts/base.dart";
import "package:loure/data/event_mem_box.dart";
import "package:loure/main.dart";
import "package:loure/provider/badge_definition_provider.dart";
import "package:loure/util/later_function.dart";
import "package:loure/component/badge_component.dart";
import "package:loure/component/badge_detail_dialog.dart";
import "package:loure/component/cust_state.dart";

// ignore: must_be_immutable
class UserBadgesComponent extends StatefulWidget {
  UserBadgesComponent({required this.pubkey, super.key});
  String pubkey;

  @override
  State<StatefulWidget> createState() {
    return _UserBadgesComponent();
  }
}

class _UserBadgesComponent extends CustState<UserBadgesComponent>
    with LaterFunction {
  @override
  Widget doBuild(final BuildContext context) {
    if (eventMemBox.isEmpty()) {
      return Container();
    }

    List<Widget> list = [];

    Map<dynamic, int> existMap = {};

    final events = eventMemBox.all();
    for (final event in events) {
      for (final tag in event.tags) {
        if (tag.length > 1) {
          if (tag[0] == "a") {
            final badgeId = tag[1];
            final itemWidget =
                Selector<BadgeDefinitionProvider, BadgeDefinition?>(builder:
                    (final context, final badgeDefinition, final child) {
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
            }, selector: (final context, final provider) {
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
  Future<void> onReady(final BuildContext context) async {
    pool.querySingle(
        ["wss://relay.nostr.band"],
        Filter(
            authors: [widget.pubkey],
            kinds: [kind.EventKind.BADGE_ACCEPT])).then((final event) {
      if (event == null) return;

      final result = eventMemBox.add(event);
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
