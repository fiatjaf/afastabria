import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:loure/util/platform_util.dart';
import 'package:provider/provider.dart';

import 'package:loure/component/keep_alive_cust_state.dart';
import 'package:loure/component/placeholder/metadata_list_placeholder.dart';
import 'package:loure/component/user/metadata_component.dart';
import 'package:loure/consts/base.dart';
import 'package:loure/consts/router_path.dart';
import 'package:loure/data/metadata.dart';
import 'package:loure/main.dart';
import 'package:loure/provider/metadata_provider.dart';
import 'package:loure/util/dio_util.dart';
import 'package:loure/util/router_util.dart';
import 'package:loure/util/string_util.dart';

class GlobalsUsersRouter extends StatefulWidget {
  const GlobalsUsersRouter({super.key});

  @override
  State<StatefulWidget> createState() {
    return _GlobalsUsersRouter();
  }
}

class _GlobalsUsersRouter extends KeepAliveCustState<GlobalsUsersRouter> {
  ScrollController scrollController = ScrollController();

  List<String> pubkeys = [];

  @override
  Widget doBuild(BuildContext context) {
    if (pubkeys.isEmpty) {
      return MetadataListPlaceholder(
        onRefresh: refresh,
      );
    }

    var main = ListView.builder(
      controller: scrollController,
      itemBuilder: (context, index) {
        var pubkey = pubkeys[index];
        if (StringUtil.isBlank(pubkey)) {
          return Container();
        }

        return Container(
          margin: const EdgeInsets.only(bottom: Base.BASE_PADDING_HALF),
          child: Selector<MetadataProvider, Metadata?>(
            builder: (context, metadata, child) {
              return GestureDetector(
                onTap: () {
                  RouterUtil.router(context, RouterPath.USER, pubkey);
                },
                behavior: HitTestBehavior.translucent,
                child: MetadataComponent(
                  pubKey: pubkey,
                  metadata: metadata,
                  jumpable: true,
                ),
              );
            },
            selector: (context, provider) {
              return provider.getMetadata(pubkey);
            },
          ),
        );
      },
      itemCount: pubkeys.length,
    );

    if (PlatformUtil.isTableMode()) {
      return GestureDetector(
        onVerticalDragUpdate: (detail) {
          scrollController.jumpTo(scrollController.offset - detail.delta.dy);
        },
        behavior: HitTestBehavior.translucent,
        child: main,
      );
    }

    return main;
  }

  @override
  Future<void> onReady(BuildContext context) async {
    indexProvider.setUserScrollController(scrollController);
    refresh();
  }

  Future<void> refresh() async {
    var str = await DioUtil.getStr(Base.INDEXS_CONTACTS);
    if (StringUtil.isNotBlank(str)) {
      pubkeys.clear();
      var itfs = jsonDecode(str!);
      for (var itf in itfs) {
        pubkeys.add(itf as String);
      }

      // Disorder
      for (var i = 1; i < pubkeys.length; i++) {
        var j = getRandomInt(0, i);
        var t = pubkeys[i];
        pubkeys[i] = pubkeys[j];
        pubkeys[j] = t;
      }

      setState(() {});
    }
  }

  int getRandomInt(int min, int max) {
    final random = Random();
    return random.nextInt((max - min).floor()) + min;
  }
}
