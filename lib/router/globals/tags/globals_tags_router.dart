import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:nostrmo/consts/router_path.dart';
import 'package:nostrmo/util/router_util.dart';

import 'package:nostrmo/component/keep_alive_cust_state.dart';
import 'package:nostrmo/component/placeholder/tap_list_placeholder.dart';
import 'package:nostrmo/consts/base.dart';
import 'package:nostrmo/util/dio_util.dart';
import 'package:nostrmo/util/string_util.dart';

class GlobalsTagsRouter extends StatefulWidget {
  const GlobalsTagsRouter({super.key});

  @override
  State<StatefulWidget> createState() {
    return _GlobalsTagsRouter();
  }
}

class _GlobalsTagsRouter extends KeepAliveCustState<GlobalsTagsRouter> {
  List<String> topics = [];

  @override
  Widget doBuild(BuildContext context) {
    var themeData = Theme.of(context);
    var mainColor = themeData.primaryColor;

    if (topics.isEmpty) {
      return const TapListPlaceholder();
    } else {
      List<Widget> list = [];
      for (var topic in topics) {
        list.add(GestureDetector(
          onTap: () {
            RouterUtil.router(context, RouterPath.TAG_DETAIL, topic);
          },
          child: Container(
            padding: const EdgeInsets.all(Base.BASE_PADDING_HALF),
            decoration: BoxDecoration(
              color: mainColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              topic,
              style: const TextStyle(
                color: Colors.white,
              ),
            ),
          ),
        ));
      }

      return Container(
        // padding: EdgeInsets.all(Base.BASE_PADDING),
        child: Center(
          child: SingleChildScrollView(
            child: Wrap(
              spacing: 14,
              runSpacing: 14,
              alignment: WrapAlignment.center,
              children: list,
            ),
          ),
        ),
      );
    }
  }

  @override
  Future<void> onReady(BuildContext context) async {
    var str = await DioUtil.getStr(Base.INDEXS_TOPICS);
    if (StringUtil.isNotBlank(str)) {
      topics.clear();
      var itfs = jsonDecode(str!);
      for (var itf in itfs) {
        topics.add(itf as String);
      }

      // Disorder
      for (var i = 1; i < topics.length; i++) {
        var j = getRandomInt(0, i);
        var t = topics[i];
        topics[i] = topics[j];
        topics[j] = t;
      }

      setState(() {});
    }
  }

  int getRandomInt(int min, int max) {
    final random = Random();
    return random.nextInt((max - min).floor()) + min;
  }
}
