import 'package:flutter/material.dart';
import 'package:get_time_ago/get_time_ago.dart';
import 'package:nostrmo/provider/notice_provider.dart';

import '../../consts/base.dart';
import '../../util/string_util.dart';

class NoticeListItemComponent extends StatelessWidget {
  NoticeData notice;

  NoticeListItemComponent({super.key, required this.notice});

  @override
  Widget build(BuildContext context) {
    var themeData = Theme.of(context);
    var hintColor = themeData.hintColor;
    var smallTextSize = themeData.textTheme.bodySmall!.fontSize;

    return Container(
      padding: const EdgeInsets.all(Base.BASE_PADDING),
      decoration: BoxDecoration(
          border: Border(
              bottom: BorderSide(
        width: 1,
        color: hintColor,
      ))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                notice.url,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Expanded(
                child: Container(
                  alignment: Alignment.centerRight,
                  child: Text(
                    GetTimeAgo.parse(DateTime.fromMillisecondsSinceEpoch(
                        notice.dateTime.millisecondsSinceEpoch)),
                    style: TextStyle(
                      fontSize: smallTextSize,
                      color: themeData.hintColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Container(
            margin: const EdgeInsets.only(top: 2),
            child: Text(
              StringUtil.breakWord(notice.content),
              style: TextStyle(
                fontSize: smallTextSize,
                color: themeData.hintColor,
                // overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
