import "package:flutter/material.dart";

import "package:loure/consts/base.dart";

class SettingGroupTitleComponent extends StatelessWidget {
  SettingGroupTitleComponent({
    required this.iconData,
    required this.title,
    super.key,
  });
  IconData iconData;

  String title;

  @override
  Widget build(final BuildContext context) {
    final themeData = Theme.of(context);
    final hintColor = themeData.hintColor;
    final fontSize = themeData.textTheme.bodyMedium!.fontSize;

    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.only(
          top: 30,
        ),
        child: Row(
          children: [
            Container(
              margin: const EdgeInsets.only(right: Base.BASE_PADDING_HALF),
              child: Icon(
                iconData,
                color: hintColor,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                color: hintColor,
                fontWeight: FontWeight.bold,
                fontSize: fontSize,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
