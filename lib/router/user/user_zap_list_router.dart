import "package:flutter/material.dart";

import "package:loure/client/event.dart";
import "package:loure/component/event/zap_event_list_component.dart";
import "package:loure/util/router_util.dart";

class UserZapListRouter extends StatefulWidget {
  const UserZapListRouter({super.key});

  @override
  State<StatefulWidget> createState() {
    return _UserZapListRouter();
  }
}

class _UserZapListRouter extends State<UserZapListRouter> {
  List<Event>? zapList;

  @override
  Widget build(final BuildContext context) {
    if (zapList == null) {
      final arg = RouterUtil.routerArgs(context);
      if (arg != null) {
        zapList = arg as List<Event>;
      }
    }
    if (zapList == null) {
      RouterUtil.back(context);
      return Container();
    }

    final themeData = Theme.of(context);
    final titleFontSize = themeData.textTheme.bodyLarge!.fontSize;

    return Scaffold(
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () {
            RouterUtil.back(context);
          },
          child: Icon(
            Icons.arrow_back_ios,
            color: themeData.appBarTheme.titleTextStyle!.color,
          ),
        ),
        title: Text(
          "⚡Zaps⚡",
          style: TextStyle(
            fontSize: titleFontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView.builder(
        itemBuilder: (final context, final index) {
          final zapEvent = zapList![index];
          return ZapEventListComponent(event: zapEvent);
        },
        itemCount: zapList!.length,
      ),
    );
  }
}
