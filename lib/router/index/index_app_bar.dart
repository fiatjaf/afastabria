import "package:flutter/material.dart";
import "package:loure/util/platform_util.dart";

import "package:loure/component/user_pic_component.dart";
import "package:loure/consts/base.dart";
import "package:loure/main.dart";

class IndexAppBar extends StatelessWidget {
  const IndexAppBar({super.key, this.center});

  static const double height = 56;
  static const double picHeight = 30;

  final Widget? center;

  @override
  Widget build(final BuildContext context) {
    final themeData = Theme.of(context);
    final paddingTop = mediaDataCache.padding.top;
    // final textColor = themeData.appBarTheme.titleTextStyle!.color;
    final appBarBackgroundColor = themeData.appBarTheme.backgroundColor;

    Widget? userPicWidget;
    if (!PlatformUtil.isTableMode()) {
      userPicWidget = GestureDetector(
        onTap: () {
          Scaffold.of(context).openDrawer();
        },
        child: UserPicComponent(
          pubkey: nostr.publicKey,
          width: picHeight,
        ),
      );
    } else {
      userPicWidget = Container(
        width: picHeight,
      );
    }

    return Container(
      padding: EdgeInsets.only(
        top: paddingTop,
        left: Base.BASE_PADDING,
        right: Base.BASE_PADDING,
      ),
      height: paddingTop + IndexAppBar.height,
      color: appBarBackgroundColor,
      child: Row(children: [
        Container(
          child: userPicWidget,
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(
              left: Base.BASE_PADDING,
              right: Base.BASE_PADDING,
            ),
            child: this.center,
          ),
        ),
      ]),
    );
  }
}
