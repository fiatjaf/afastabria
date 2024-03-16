import "package:flutter/material.dart";
import "package:loure/client/event.dart";
import "package:loure/client/nip58/badge_definition.dart";
import "package:loure/consts/base.dart";
import "package:loure/main.dart";
import "package:loure/provider/badge_definition_provider.dart";
import "package:loure/provider/badge_provider.dart";
import "package:provider/provider.dart";

import "package:loure/component/badge_detail_component.dart";

// ignore: must_be_immutable
class BadgeAwardComponent extends StatefulWidget {
  BadgeAwardComponent({
    required this.event,
    super.key,
  });
  Event event;

  @override
  State<StatefulWidget> createState() {
    return _BadgeAwardComponent();
  }
}

class _BadgeAwardComponent extends State<BadgeAwardComponent> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    var badgeId = "";
    for (final tag in widget.event.tags) {
      if (tag[0] == "a") {
        badgeId = tag[1];
      }
    }

    if (badgeId == "") {
      return Container();
    }

    final badgeDetailComp = Selector<BadgeDefinitionProvider, BadgeDefinition?>(
        builder: (final context, final badgeDefinition, final child) {
      if (badgeDefinition == null) {
        return Container();
      }

      return BadgeDetailComponent(
        badgeDefinition: badgeDefinition,
      );
    }, selector: (final context, final provider) {
      return provider.get(badgeId, widget.event.pubKey);
    });

    List<Widget> list = [badgeDetailComp];

    final wearComp = Selector<BadgeProvider, bool>(
      builder: (final context, final exist, final child) {
        if (exist) {
          return Container();
        }

        return GestureDetector(
          onTap: () {
            String? source;
            if (widget.event.sources.isNotEmpty) {
              source = widget.event.sources.first;
            }
            badgeProvider.wear(badgeId, widget.event.id, relayAddr: source);
          },
          child: Container(
            margin: const EdgeInsets.only(top: Base.BASE_PADDING_HALF),
            padding: const EdgeInsets.only(
              left: Base.BASE_PADDING,
              right: Base.BASE_PADDING,
            ),
            color: theme.primaryColor,
            width: double.infinity,
            height: 40,
            alignment: Alignment.center,
            child: const Text(
              "Wear",
              style: TextStyle(
                color: Colors.white,
              ),
            ),
          ),
        );
      },
      selector: (final context, final badgeProvider) {
        return badgeProvider.containBadge(badgeId);
      },
    );
    list.add(wearComp);

    return Container(
      padding: const EdgeInsets.all(Base.BASE_PADDING),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: list,
      ),
    );
  }
}
