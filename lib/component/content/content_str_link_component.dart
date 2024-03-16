import "package:flutter/material.dart";
import "package:loure/util/string_util.dart";

class ContentStrLinkComponent extends StatelessWidget {
  ContentStrLinkComponent(
      {required this.str,
      required this.onTap,
      super.key,
      this.showUnderline = true});
  bool showUnderline;

  String str;

  Function onTap;

  @override
  Widget build(final BuildContext context) {
    final themeData = Theme.of(context);
    final mainColor = themeData.primaryColor;
    final fontSize = themeData.textTheme.bodyMedium!.fontSize;

    return GestureDetector(
      onTap: () {
        onTap();
      },
      child: Text(
        StringUtil.breakWord(str),
        style: TextStyle(
          color: mainColor,
          decoration:
              showUnderline ? TextDecoration.underline : TextDecoration.none,
          decorationColor: mainColor,
          fontSize: fontSize,
        ),
        // fix when flutter upgrade, text not vertical align by bottom
        strutStyle: StrutStyle(
          forceStrutHeight: true,
          fontSize: fontSize! + 2,
        ),
      ),
    );
  }
}
