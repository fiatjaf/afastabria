import "package:flutter/material.dart";
import "package:loure/component/webview_router.dart";

import "package:loure/consts/base.dart";

class WebUtilItemComponent extends StatelessWidget {
  WebUtilItemComponent({required this.link, required this.des, super.key});
  String link;

  String des;

  @override
  Widget build(final BuildContext context) {
    final themeData = Theme.of(context);
    final cardColor = themeData.cardColor;
    final hintColor = themeData.hintColor;
    final largeTextSize = themeData.textTheme.bodyLarge!.fontSize;

    final main = Container(
      width: double.maxFinite,
      color: cardColor,
      margin: const EdgeInsets.only(bottom: Base.BASE_PADDING_HALF),
      padding: const EdgeInsets.all(
        Base.BASE_PADDING,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 3),
            child: Text(
              link,
              style: TextStyle(
                fontSize: largeTextSize,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Text(
            des,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: hintColor,
            ),
          ),
        ],
      ),
    );

    return GestureDetector(
      onTap: () {
        WebViewRouter.open(context, link);
      },
      behavior: HitTestBehavior.translucent,
      child: main,
    );
  }
}
