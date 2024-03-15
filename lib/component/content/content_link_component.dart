import 'package:flutter/material.dart';
import 'package:loure/component/content/content_str_link_component.dart';
import 'package:loure/component/webview_router.dart';

class ContentLinkComponent extends StatelessWidget {
  String link;

  String? title;

  ContentLinkComponent({super.key, 
    required this.link,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    return ContentStrLinkComponent(
      str: title != null ? title! : link,
      onTap: () {
        WebViewRouter.open(context, link);
      },
    );
  }
}
