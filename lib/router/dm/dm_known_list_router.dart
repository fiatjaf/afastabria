import "package:flutter/material.dart";
import "package:loure/provider/notice_provider.dart";
import "package:pointycastle/ecc/api.dart";
import "package:provider/provider.dart";

import "package:loure/provider/dm_provider.dart";
import "package:loure/router/dm/dm_notice_item_component.dart";
import "package:loure/router/dm/dm_session_list_item_component.dart";

class DMKnownListRouter extends StatefulWidget {
  DMKnownListRouter({required this.agreement, super.key});
  ECDHBasicAgreement agreement;

  @override
  State<StatefulWidget> createState() {
    return _DMKnownListRouter();
  }
}

class _DMKnownListRouter extends State<DMKnownListRouter> {
  @override
  Widget build(final BuildContext context) {
    final dmProvider = Provider.of<DMProvider>(context);
    final details = dmProvider.knownList;
    var allLength = details.length;

    final noticeProvider = Provider.of<NoticeProvider>(context);
    final notices = noticeProvider.notices;
    final bool hasNewNotice = noticeProvider.hasNewMessage();
    int flag = 0;
    if (notices.isNotEmpty) {
      allLength += 1;
      flag = 1;
    }

    return Container(
      child: ListView.builder(
        itemBuilder: (final context, final index) {
          if (index >= allLength) {
            return null;
          }

          if (index == 0 && flag > 0) {
            return DMNoticeItemComponent(
              newestNotice: notices.last,
              hasNewMessage: hasNewNotice,
            );
          } else {
            final detail = details[index - flag];
            return DMSessionListItemComponent(
              detail: detail,
              agreement: widget.agreement,
            );
          }
        },
        itemCount: allLength,
      ),
    );
  }
}
