import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:loure/provider/notice_provider.dart';
import 'package:loure/router/edit/editor_router.dart';
import 'package:loure/router/notice/notice_list_item_component.dart';

class NoticeRouter extends StatefulWidget {
  const NoticeRouter({super.key});

  @override
  State<StatefulWidget> createState() {
    return _NoticeRouter();
  }
}

class _NoticeRouter extends State<NoticeRouter> {
  @override
  Widget build(BuildContext context) {
    
    var noticeProvider = Provider.of<NoticeProvider>(context);
    var notices = noticeProvider.notices;
    var length = notices.length;

    Widget? main;
    if (length == 0) {
      main = Container(
        child: Center(
          child: GestureDetector(
            onTap: () {
              EditorRouter.open(context);
            },
            child: const Text("Notices"),
          ),
        ),
      );
    } else {
      main = ListView.builder(
        itemBuilder: (BuildContext context, int index) {
          var notice = notices[length - 1 - index];
          return NoticeListItemComponent(
            notice: notice,
          );
        },
        itemCount: length,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Notices"),
      ),
      body: main,
    );
  }
}
