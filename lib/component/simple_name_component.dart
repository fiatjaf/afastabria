import "package:flutter/material.dart";
import "package:loure/main.dart";

import "package:loure/client/nip19/nip19.dart";
import "package:loure/data/metadata.dart";
import "package:loure/util/string_util.dart";

class SimpleNameComponent extends StatefulWidget {
  const SimpleNameComponent({
    required this.pubkey,
    super.key,
    this.textStyle,
  });
  final String pubkey;
  final TextStyle? textStyle;

  @override
  State<StatefulWidget> createState() {
    return SimpleNameComponentState();
  }

  static String getSimpleName(final String pubkey, final Metadata? metadata) {
    String? name;
    if (metadata != null) {
      if (StringUtil.isNotBlank(metadata.displayName)) {
        name = metadata.displayName;
      } else if (StringUtil.isNotBlank(metadata.name)) {
        name = metadata.name;
      }
    }
    if (StringUtil.isBlank(name)) {
      name = Nip19.encodeSimplePubKey(pubkey);
    }

    return name!;
  }
}

class SimpleNameComponentState extends State<SimpleNameComponent> {
  @override
  Widget build(final BuildContext context) {
    return FutureBuilder(
        future: metadataLoader.load(widget.pubkey),
        initialData: Metadata.blank(widget.pubkey),
        builder: (final context, final snapshot) {
          final name =
              SimpleNameComponent.getSimpleName(widget.pubkey, snapshot.data);
          return Text(
            name,
            style: widget.textStyle,
          );
        });
  }
}
