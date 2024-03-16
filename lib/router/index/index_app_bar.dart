import "package:flutter/material.dart";
import "package:loure/util/platform_util.dart";

import "package:loure/component/user_pic_component.dart";
import "package:loure/consts/base.dart";
import "package:loure/consts/router_path.dart";
import "package:loure/main.dart";
import "package:loure/util/router_util.dart";

class IndexAppBar extends StatefulWidget {
  IndexAppBar({super.key, this.center});
  static const double height = 56;

  Widget? center;

  @override
  State<StatefulWidget> createState() {
    return _IndexAppBar();
  }
}

class _IndexAppBar extends State<IndexAppBar> {
  double picHeight = 30;

  @override
  Widget build(final BuildContext context) {
    final themeData = Theme.of(context);
    final paddingTop = mediaDataCache.padding.top;
    final textColor = themeData.appBarTheme.titleTextStyle!.color;
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

    var center = widget.center;
    center ??= Container();

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
            child: center,
          ),
        ),
        GestureDetector(
          onTap: () {
            RouterUtil.router(context, RouterPath.RELAYS);
          },
          child: Text("relays", style: TextStyle(color: textColor)),
        ),
      ]),
    );
  }
}
