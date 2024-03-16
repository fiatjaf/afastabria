import "package:flutter/material.dart";

import "package:loure/component/simple_name_component.dart";
import "package:loure/main.dart";
import "package:loure/consts/router_path.dart";
import "package:loure/data/metadata.dart";
import "package:loure/util/router_util.dart";
import "package:loure/component/content/content_str_link_component.dart";

class ContentMentionUserComponent extends StatefulWidget {
  const ContentMentionUserComponent({required this.pubkey, super.key});
  final String pubkey;

  @override
  State<StatefulWidget> createState() {
    return ContentMentionUserComponentState();
  }
}

class ContentMentionUserComponentState
    extends State<ContentMentionUserComponent> {
  @override
  Widget build(final BuildContext context) {
    return FutureBuilder(
      future: metadataLoader.load(widget.pubkey),
      initialData: Metadata.blank(widget.pubkey),
      builder: (final context, final snapshot) {
        final metadata = snapshot.data;

        final String name =
            SimpleNameComponent.getSimpleName(widget.pubkey, metadata);

        return ContentStrLinkComponent(
          str: "@$name",
          showUnderline: false,
          onTap: () {
            RouterUtil.router(context, RouterPath.USER, widget.pubkey);
          },
        );
      },
    );
  }
}
