import "package:flutter/material.dart";
import "package:pointycastle/export.dart" as pointycastle;
import "package:get_time_ago/get_time_ago.dart";

import "package:loure/client/nip04/nip04.dart";
import "package:loure/component/name_component.dart";
import "package:loure/component/point_component.dart";
import "package:loure/component/user_pic_component.dart";
import "package:loure/consts/base.dart";
import "package:loure/router/routes.dart";
import "package:loure/client/metadata.dart";
import "package:loure/main.dart";
import "package:loure/provider/dm_provider.dart";
import "package:loure/util/router_util.dart";
import "package:loure/util/string_util.dart";

class DMSessionListItemComponent extends StatefulWidget {
  const DMSessionListItemComponent({
    required this.detail,
    required this.agreement,
    super.key,
  });
  final DMSessionDetail detail;
  final pointycastle.ECDHBasicAgreement agreement;

  @override
  State<StatefulWidget> createState() {
    return DMSessionListItemComponentState();
  }
}

class DMSessionListItemComponentState
    extends State<DMSessionListItemComponent> {
  static const double IMAGE_WIDTH = 34;
  static const double HALF_IMAGE_WIDTH = 17;

  @override
  Widget build(final BuildContext context) {
    return GestureDetector(
      onTap: () {
        RouterUtil.router(context, RouterPath.DM_DETAIL, widget.detail);
      },
      child: FutureBuilder(
        future: metadataLoader.load(widget.detail.dmSession.pubkey),
        initialData: Metadata.blank(widget.detail.dmSession.pubkey),
        builder: (final context, final snapshot) {
          final metadata = snapshot.data;

          final themeData = Theme.of(context);
          final mainColor = themeData.primaryColor;
          final hintColor = themeData.hintColor;
          final smallTextSize = themeData.textTheme.bodySmall!.fontSize;

          final dmSession = widget.detail.dmSession;

          var content = NIP04.decrypt(dmSession.newestEvent!.content,
              widget.agreement, dmSession.pubkey);
          content = content.replaceAll("\r", " ");
          content = content.replaceAll("\n", " ");

          final leftWidget = Container(
            margin: const EdgeInsets.only(top: 4),
            child: UserPicComponent(
              pubkey: dmSession.pubkey,
              width: IMAGE_WIDTH,
            ),
          );

          final lastEvent = dmSession.newestEvent!;

          final bool hasNewMessage = widget.detail.hasNewMessage();

          List<Widget> contentList = [
            Expanded(
              child: Text(
                StringUtil.breakWord(content),
                style: TextStyle(
                  fontSize: smallTextSize,
                  color: themeData.hintColor,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )
          ];
          if (hasNewMessage) {
            contentList.add(
              PointComponent(color: mainColor),
            );
          }

          return Container(
            padding: const EdgeInsets.all(Base.BASE_PADDING),
            decoration: BoxDecoration(
                border: Border(
                    bottom: BorderSide(
              width: 1,
              color: hintColor,
            ))),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                leftWidget,
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.only(
                      left: Base.BASE_PADDING,
                      right: Base.BASE_PADDING,
                      top: 4,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: NameComponent(
                                pubkey: dmSession.pubkey,
                                metadata: metadata,
                                maxLines: 1,
                                textOverflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              alignment: Alignment.centerRight,
                              child: Text(
                                GetTimeAgo.parse(
                                    DateTime.fromMillisecondsSinceEpoch(
                                        lastEvent.createdAt * 1000)),
                                style: TextStyle(
                                  fontSize: smallTextSize,
                                  color: themeData.hintColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          child: Row(children: contentList),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
