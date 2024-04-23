import "package:flutter/material.dart";
import "package:loure/main.dart";

import "package:loure/component/user/metadata_component.dart";
import "package:loure/consts/base.dart";
import "package:loure/router/routes.dart";
import "package:loure/client/metadata.dart";
import "package:loure/util/platform_util.dart";
import "package:loure/util/router_util.dart";

class FollowedRouter extends StatefulWidget {
  const FollowedRouter({super.key});

  @override
  State<StatefulWidget> createState() {
    return FollowedRouterState();
  }
}

class FollowedRouterState extends State<FollowedRouter> {
  ScrollController scrollController = ScrollController();

  @override
  Widget build(final BuildContext context) {
    final arg = RouterUtil.routerArgs(context);
    final pubkeys = (arg ?? []) as List<String>;

    final themeData = Theme.of(context);
    final titleFontSize = themeData.textTheme.bodyLarge!.fontSize;

    final listView = ListView.builder(
      controller: scrollController,
      itemBuilder: (final context, final index) {
        final pubkey = pubkeys[index];

        return Container(
          margin: const EdgeInsets.only(bottom: Base.BASE_PADDING_HALF),
          child: FutureBuilder(
            future: metadataLoader.load(pubkey),
            initialData: Metadata.blank(pubkey),
            builder: (final context, final snapshot) {
              return GestureDetector(
                onTap: () {
                  RouterUtil.router(context, RouterPath.USER, pubkey);
                },
                behavior: HitTestBehavior.translucent,
                child: MetadataComponent(
                  pubkey: pubkey,
                  metadata: snapshot.data!,
                  jumpable: true,
                ),
              );
            },
          ),
        );
      },
      itemCount: pubkeys.length,
    );

    final main = Scaffold(
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
          "Followed",
          style: TextStyle(
            fontSize: titleFontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: listView,
    );

    if (PlatformUtil.isTableMode()) {
      return GestureDetector(
        onVerticalDragUpdate: (final detail) {
          scrollController.jumpTo(scrollController.offset - detail.delta.dy);
        },
        behavior: HitTestBehavior.translucent,
        child: main,
      );
    }

    return main;
  }
}
