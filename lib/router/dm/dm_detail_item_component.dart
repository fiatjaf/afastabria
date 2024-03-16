import "package:flutter/material.dart";
import "package:get_time_ago/get_time_ago.dart";
import "package:loure/client/nip04/nip04.dart";
import "package:loure/component/content/content_component.dart";
import "package:loure/consts/router_path.dart";
import "package:loure/util/router_util.dart";
import "package:pointycastle/export.dart" as pointycastle;
import "package:provider/provider.dart";

import "package:loure/client/event.dart";
import "package:loure/component/user_pic_component.dart";
import "package:loure/consts/base.dart";
import "package:loure/consts/base_consts.dart";
import "package:loure/provider/setting_provider.dart";

class DMDetailItemComponent extends StatefulWidget {
  DMDetailItemComponent({
    required this.sessionPubkey,
    required this.event,
    required this.isLocal,
    required this.agreement,
    super.key,
  });
  String sessionPubkey;

  Event event;

  bool isLocal;

  pointycastle.ECDHBasicAgreement agreement;

  @override
  State<StatefulWidget> createState() {
    return _DMDetailItemComponent();
  }
}

class _DMDetailItemComponent extends State<DMDetailItemComponent> {
  static const double IMAGE_WIDTH = 34;

  static const double BLANK_WIDTH = 50;

  @override
  Widget build(final BuildContext context) {
    final settingProvider = Provider.of<SettingProvider>(context);
    final themeData = Theme.of(context);
    final mainColor = themeData.primaryColor;
    Widget userHeadWidget = Container(
      margin: const EdgeInsets.only(top: 2),
      child: UserPicComponent(
        pubkey: widget.event.pubKey,
        width: IMAGE_WIDTH,
      ),
    );
    // var maxWidth = mediaDataCache.size.width;
    final smallTextSize = themeData.textTheme.bodySmall!.fontSize;
    final hintColor = themeData.hintColor;

    final String timeStr = GetTimeAgo.parse(
        DateTime.fromMillisecondsSinceEpoch(widget.event.createdAt * 1000));

    final content = NIP04.decrypt(
        widget.event.content, widget.agreement, widget.sessionPubkey);

    final contentWidget = Container(
      margin: const EdgeInsets.only(
        left: Base.BASE_PADDING_HALF,
        right: Base.BASE_PADDING_HALF,
      ),
      child: Column(
        crossAxisAlignment:
            !widget.isLocal ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            timeStr,
            style: TextStyle(
              color: hintColor,
              fontSize: smallTextSize,
            ),
          ),
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.only(
              top: Base.BASE_PADDING_HALF - 1,
              right: Base.BASE_PADDING_HALF,
              bottom: Base.BASE_PADDING_HALF,
              left: Base.BASE_PADDING_HALF + 1,
            ),
            // constraints:
            //     BoxConstraints(maxWidth: (maxWidth - IMAGE_WIDTH) * 0.85),
            decoration: BoxDecoration(
              // color: Colors.red,
              color: mainColor.withOpacity(0.3),
              borderRadius: const BorderRadius.all(Radius.circular(5)),
            ),
            // child: SelectableText(content),
            child: Column(
              crossAxisAlignment: widget.isLocal
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                ContentComponent(
                  content: content,
                  event: widget.event,
                  showLinkPreview:
                      settingProvider.linkPreview == OpenStatus.OPEN,
                  smallest: true,
                ),
              ],
              // children: ContentDecoder.decode(
              //   context,
              //   content,
              //   widget.event,
              //   showLinkPreview:
              //       _settingProvider.linkPreview == OpenStatus.OPEN,
              // ),
            ),
          ),
        ],
      ),
    );

    // if (!widget.isLocal) {
    userHeadWidget = GestureDetector(
      onTap: () {
        RouterUtil.router(context, RouterPath.USER, widget.event.pubKey);
      },
      child: userHeadWidget,
    );
    // }

    List<Widget> list = [];
    if (widget.isLocal) {
      list.add(Container(width: BLANK_WIDTH));
      list.add(Expanded(child: contentWidget));
      list.add(userHeadWidget);
    } else {
      list.add(userHeadWidget);
      list.add(Expanded(child: contentWidget));
      list.add(Container(width: BLANK_WIDTH));
    }

    return Container(
      padding: const EdgeInsets.all(Base.BASE_PADDING_HALF),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: list,
      ),
    );
  }
}
