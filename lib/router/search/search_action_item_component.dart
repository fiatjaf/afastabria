import "package:flutter/material.dart";

import "package:loure/consts/base.dart";

class SearchActionItemComponent extends StatelessWidget {
  SearchActionItemComponent({
    required this.title,
    required this.onTap,
    super.key,
  });
  String title;

  Function onTap;

  @override
  Widget build(final BuildContext context) {
    final themeData = Theme.of(context);
    final fontSize = themeData.textTheme.bodyLarge!.fontSize;
    final hintColor = themeData.hintColor;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        onTap();
      },
      child: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(
          left: Base.BASE_PADDING * 2,
          right: Base.BASE_PADDING * 2,
          top: Base.BASE_PADDING,
          bottom: Base.BASE_PADDING,
        ),
        decoration: BoxDecoration(
            border: Border(
                bottom: BorderSide(
          width: 1,
          color: hintColor,
        ))),
        child: Text(
          title,
          style: TextStyle(fontSize: fontSize),
        ),
      ),
    );
  }
}
