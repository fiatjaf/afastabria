import 'package:flutter/material.dart';
import 'package:nostrmo/client/nip58/badge_definition.dart';

import 'package:nostrmo/consts/base.dart';
import 'package:nostrmo/util/router_util.dart';
import 'package:nostrmo/component/badge_detail_component.dart';

class BadgeDetailDialog extends StatefulWidget {
  BadgeDefinition badgeDefinition;

  BadgeDetailDialog({super.key, 
    required this.badgeDefinition,
  });

  static Future<bool?> show(
      BuildContext context, BadgeDefinition badgeDefinition) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) {
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
  Widget build(BuildContext context) {
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
