import "package:flutter/material.dart";
import "package:loure/client/nip58/badge_definition.dart";

import "package:loure/consts/base.dart";
import "package:loure/util/router_util.dart";
import "package:loure/component/badge_detail_component.dart";

class BadgeDetailDialog extends StatefulWidget {
  BadgeDetailDialog({
    required this.badgeDefinition,
    super.key,
  });
  BadgeDefinition badgeDefinition;

  static Future<bool?> show(
      final BuildContext context, final BadgeDefinition badgeDefinition) async {
    return await showDialog<bool>(
      context: context,
      builder: (final context) {
        return BadgeDetailDialog(
          badgeDefinition: badgeDefinition,
        );
      },
    );
  }

  @override
  State<StatefulWidget> createState() {
    return _BadgeDetailDialog();
  }
}

class _BadgeDetailDialog extends State<BadgeDetailDialog> {
  @override
  Widget build(final BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.2),
      body: FocusScope(
        // autofocus: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            RouterUtil.back(context);
          },
          child: Container(
            width: double.infinity,
            height: double.infinity,
            padding: const EdgeInsets.only(
              left: Base.BASE_PADDING,
              right: Base.BASE_PADDING,
            ),
            alignment: Alignment.center,
            child: GestureDetector(
              onTap: () {},
              child: BadgeDetailComponent(
                badgeDefinition: widget.badgeDefinition,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
