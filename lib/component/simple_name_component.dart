import "package:flutter/material.dart";
import "package:loure/main.dart";

import "package:loure/client/nip19/nip19.dart";
import "package:loure/data/metadata.dart";
import "package:loure/util/string_util.dart";

class SimpleNameComponent extends StatelessWidget {
  const SimpleNameComponent({
    required this.pubkey,
    super.key,
    this.textStyle,
  });
  final String pubkey;
  final TextStyle? textStyle;

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
      name = NIP19.encodeSimplePubKey(pubkey);
    }

    return name!;
  }

  @override
  Widget build(final BuildContext context) {
    return FutureBuilder(
        future: metadataLoader.load(this.pubkey),
        initialData: Metadata.blank(this.pubkey),
        builder: (final context, final snapshot) {
          final name =
              SimpleNameComponent.getSimpleName(this.pubkey, snapshot.data);
          return Text(
            name,
            style: this.textStyle,
          );
        });
  }
}
