import "package:flutter/material.dart";
import "package:loure/router/search/search_router.dart";
import "package:loure/util/router_util.dart";

import "package:loure/component/content/content_str_link_component.dart";

class ContentTagComponent extends StatelessWidget {
  const ContentTagComponent({required this.tag, super.key});

  final String tag;

  @override
  Widget build(final BuildContext context) {
    return ContentStrLinkComponent(
      str: tag,
      onTap: () {
        RouterUtil.push(context, SearchRouter(query: tag));
      },
    );
  }
}
