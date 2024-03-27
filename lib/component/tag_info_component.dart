import "package:flutter/material.dart";
import "package:loure/main.dart";
import "package:loure/provider/contact_list_provider.dart";
import "package:loure/router/search/search_router.dart";
import "package:loure/util/router_util.dart";
import "package:provider/provider.dart";

import "package:loure/consts/base.dart";

class TagInfoComponent extends StatelessWidget {
  const TagInfoComponent({
    required this.tag,
    super.key,
    this.height = 80,
    this.jumpable = false,
  });

  final String tag;
  final double height;
  final bool jumpable;

  @override
  Widget build(final BuildContext context) {
    final themeData = Theme.of(context);
    final cardColor = themeData.cardColor;
    final bodyLargeFontSize = themeData.textTheme.bodyLarge!.fontSize;

    final main = Container(
      height: this.height,
      color: cardColor,
      alignment: Alignment.center,
      margin: const EdgeInsets.only(bottom: Base.BASE_PADDING_HALF),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "#${this.tag}",
            style: TextStyle(
              fontSize: bodyLargeFontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
          Selector<ContactListProvider, bool>(
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
                  contactListProvider.removeTag(this.tag);
                } else {
                  contactListProvider.addTag(this.tag);
                }
              },
              child: Container(
                margin: const EdgeInsets.only(left: Base.BASE_PADDING_HALF),
                child: Icon(
                  iconData,
                  color: color,
                ),
              ),
            );
          }, selector: (final context, final provider) {
            return provider.containTag(this.tag);
          }),
        ],
      ),
    );

    if (this.jumpable) {
      return GestureDetector(
        onTap: () {
          RouterUtil.push(context, SearchRouter(query: "#${this.tag}"));
        },
        behavior: HitTestBehavior.translucent,
        child: main,
      );
    } else {
      return main;
    }
  }
}
