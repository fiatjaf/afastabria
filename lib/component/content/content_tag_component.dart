import 'package:flutter/material.dart';
import 'package:loure/consts/router_path.dart';
import 'package:loure/util/router_util.dart';

import 'package:loure/component/content/content_str_link_component.dart';

class ContentTagComponent extends StatelessWidget {
  String tag;

  ContentTagComponent({super.key, required this.tag});

  @override
  Widget build(BuildContext context) {
    return ContentStrLinkComponent(
      str: tag,
      onTap: () {
        var plainTag = tag.replaceFirst("#", "");
        RouterUtil.router(context, RouterPath.TAG_DETAIL, plainTag);
      },
    );
  }
}
