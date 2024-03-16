import "package:flutter/material.dart";
import "package:loure/consts/base.dart";
import "package:loure/provider/contact_list_provider.dart";
import "package:loure/util/string_util.dart";
import "package:provider/provider.dart";

import "package:loure/client/nip172/community_info.dart";
import "package:loure/main.dart";
import "package:loure/component/content/content_component.dart";
import "package:loure/component/image_component.dart";

class CommunityInfoComponent extends StatefulWidget {
  const CommunityInfoComponent({required this.info, super.key});
  final CommunityInfo info;

  @override
  State<StatefulWidget> createState() {
    return _CommunityInfoComponent();
  }
}

class _CommunityInfoComponent extends State<CommunityInfoComponent> {
  static const double IMAGE_WIDTH = 40;

  @override
  Widget build(final BuildContext context) {
    final themeData = Theme.of(context);
    final cardColor = themeData.cardColor;

    Widget? imageWidget;
    if (StringUtil.isNotBlank(widget.info.image)) {
      imageWidget = ImageComponent(
        imageUrl: widget.info.image!,
        width: IMAGE_WIDTH,
        height: IMAGE_WIDTH,
        fit: BoxFit.cover,
        placeholder: (final context, final url) =>
            const CircularProgressIndicator(),
      );
    }

    final Widget followBtn = Selector<ContactListProvider, bool>(
        builder: (final context, final exist, final child) {
      IconData iconData = Icons.star_border;
      Color? color;
      if (exist) {
        iconData = Icons.star;
        color = Colors.yellow;
      }

      return GestureDetector(
        onTap: () {
          if (exist) {
            contactListProvider.removeCommunity(widget.info.aId.toTag());
          } else {
            contactListProvider.addCommunity(widget.info.aId.toTag());
          }
        },
        child: Container(
          margin: const EdgeInsets.only(
            left: Base.BASE_PADDING_HALF,
            right: Base.BASE_PADDING_HALF,
          ),
          child: Icon(
            iconData,
            color: color,
          ),
        ),
      );
    }, selector: (final context, final provider) {
      return provider.containCommunity(widget.info.aId.toTag());
    });

    List<Widget> list = [
      Container(
        margin: const EdgeInsets.only(bottom: Base.BASE_PADDING_HALF),
        child: Row(
          children: [
            Container(
              alignment: Alignment.center,
              height: IMAGE_WIDTH,
              width: IMAGE_WIDTH,
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(IMAGE_WIDTH / 2),
                color: Colors.grey,
              ),
              child: imageWidget,
            ),
            Container(
              margin: const EdgeInsets.only(
                left: Base.BASE_PADDING,
              ),
              child: Text(
                widget.info.aId.identifier,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            followBtn,
          ],
        ),
      ),
    ];

    list.add(ContentComponent(
      content: widget.info.description,
      event: widget.info.event,
    ));

    return Container(
      decoration: BoxDecoration(color: cardColor),
      padding: const EdgeInsets.all(Base.BASE_PADDING),
      margin: const EdgeInsets.only(bottom: Base.BASE_PADDING_HALF),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: list,
      ),
    );
  }
}
