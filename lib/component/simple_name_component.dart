import 'package:flutter/material.dart';
import 'package:loure/main.dart';

import 'package:loure/client/nip19/nip19.dart';
import 'package:loure/data/metadata.dart';
import 'package:loure/util/string_util.dart';

class SimpleNameComponent extends StatefulWidget {
  final String pubkey;
  final TextStyle? textStyle;

  const SimpleNameComponent({
    super.key,
    required this.pubkey,
    this.textStyle,
  });

  @override
  State<StatefulWidget> createState() {
    return SimpleNameComponentState();
  }

  static String getSimpleName(String pubkey, Metadata? metadata) {
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
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: metadataLoader.load(widget.pubkey),
        initialData: Metadata.blank(widget.pubkey),
        builder: (context, snapshot) {
          var name =
              SimpleNameComponent.getSimpleName(widget.pubkey, snapshot.data);
          return Text(
            name,
            style: widget.textStyle,
          );
        });
  }
}
