import "package:flutter/material.dart";
import "package:loure/component/content/content_str_link_component.dart";
import "package:loure/component/webview_router.dart";

class ContentLinkComponent extends StatelessWidget {
  ContentLinkComponent({
    required this.link,
    super.key,
    this.title,
  });
  String link;

  String? title;

  @override
  Widget build(final BuildContext context) {
    return ContentStrLinkComponent(
      str: title != null ? title! : link,
      onTap: () {
        WebViewRouter.open(context, link);
      },
    );
  }
}
