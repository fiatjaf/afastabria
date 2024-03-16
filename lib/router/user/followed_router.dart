import "package:flutter/material.dart";
import "package:loure/main.dart";

import "package:loure/component/user/metadata_component.dart";
import "package:loure/consts/base.dart";
import "package:loure/consts/router_path.dart";
import "package:loure/data/metadata.dart";
import "package:loure/util/platform_util.dart";
import "package:loure/util/router_util.dart";
import "package:loure/util/string_util.dart";

class FollowedRouter extends StatefulWidget {
  const FollowedRouter({super.key});

  @override
  State<StatefulWidget> createState() {
    return _FollowedRouter();
  }
}

class _FollowedRouter extends State<FollowedRouter> {
  ScrollController scrollController = ScrollController();

  List<String>? pubkeys;
  List<Future<Metadata>>? metadataFutures;

  @override
  void initState() {
    super.initState();

    final arg = RouterUtil.routerArgs(context);
    if (arg != null) {
      this.pubkeys = arg as List<String>;
    }

    if (this.pubkeys == null) {
      RouterUtil.back(context);
      return;
    }

    this.metadataFutures = this.pubkeys!.map(metadataLoader.load).toList();
  }

  @override
  Widget build(final BuildContext context) {
    if (this.metadataFutures == null) {
      return Container();
    }

    final themeData = Theme.of(context);
    final titleFontSize = themeData.textTheme.bodyLarge!.fontSize;

    final listView = ListView.builder(
      controller: scrollController,
      itemBuilder: (final context, final index) {
        final pubkey = pubkeys![index];
        if (StringUtil.isBlank(pubkey)) {
          return Container();
        }

        return Container(
          margin: const EdgeInsets.only(bottom: Base.BASE_PADDING_HALF),
          child: FutureBuilder(
            future: this.metadataFutures![index],
            initialData: Metadata.blank(pubkey),
            builder: (final context, final snapshot) {
              return GestureDetector(
                onTap: () {
                  RouterUtil.router(context, RouterPath.USER, pubkey);
                },
                behavior: HitTestBehavior.translucent,
                child: MetadataComponent(
                  pubKey: pubkey,
                  metadata: snapshot.data,
                  jumpable: true,
                ),
              );
            },
          ),
        );
      },
      itemCount: pubkeys!.length,
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
