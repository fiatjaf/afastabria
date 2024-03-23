import "package:flutter/material.dart";
import "package:loure/component/image_component.dart";
import "package:loure/component/simple_name_component.dart";
import "package:loure/component/user_pic_component.dart";
import "package:loure/consts/base.dart";
import "package:loure/router/routes.dart";
import "package:loure/util/router_util.dart";
import "package:loure/util/string_util.dart";

import "package:loure/client/nip58/badge_definition.dart";

class BadgeDetailComponent extends StatefulWidget {
  const BadgeDetailComponent({
    required this.badgeDefinition,
    super.key,
  });
  final BadgeDefinition badgeDefinition;

  @override
  State<StatefulWidget> createState() {
    return BadgeDetailComponentState();
  }
}

class BadgeDetailComponentState extends State<BadgeDetailComponent> {
  @override
  Widget build(final BuildContext context) {
    final themeData = Theme.of(context);
    final cardColor = themeData.cardColor;
    final titleFontSize = themeData.textTheme.bodyLarge!.fontSize;

    List<Widget> list = [];

    if (StringUtil.isNotBlank(widget.badgeDefinition.image)) {
      list.add(Container(
        padding: const EdgeInsets.only(
          top: Base.BASE_PADDING,
          left: Base.BASE_PADDING,
          right: Base.BASE_PADDING,
        ),
        child: ImageComponent(imageUrl: widget.badgeDefinition.image!),
      ));
    }

    if (StringUtil.isNotBlank(widget.badgeDefinition.name)) {
      list.add(Container(
        margin: const EdgeInsets.only(top: Base.BASE_PADDING),
        child: Text(
          widget.badgeDefinition.name!,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: titleFontSize,
          ),
          textAlign: TextAlign.center,
        ),
      ));
    }

    if (StringUtil.isNotBlank(widget.badgeDefinition.description)) {
      list.add(Container(
        margin: const EdgeInsets.only(top: Base.BASE_PADDING),
        child: Text(
          widget.badgeDefinition.description!,
          textAlign: TextAlign.center,
        ),
      ));
    }

    if (StringUtil.isNotBlank(widget.badgeDefinition.pubkey)) {
      list.add(Container(
        margin: const EdgeInsets.only(top: Base.BASE_PADDING),
        child: Row(
          children: [
            const Expanded(child: Text("Creator")),
            GestureDetector(
              onTap: () {
                RouterUtil.router(
                    context, RouterPath.USER, widget.badgeDefinition.pubkey);
              },
              behavior: HitTestBehavior.translucent,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  UserPicComponent(
                      pubkey: widget.badgeDefinition.pubkey, width: 26),
                  Container(
                    margin: const EdgeInsets.only(left: Base.BASE_PADDING_HALF),
                    child: SimpleNameComponent(
                        pubkey: widget.badgeDefinition.pubkey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ));
    }

    return Container(
      padding: const EdgeInsets.all(Base.BASE_PADDING * 2),
      color: cardColor,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: list,
      ),
    );
  }
}
