import 'package:flutter/material.dart';
import 'package:loure/component/nip05_valid_component.dart';
import 'package:loure/data/metadata.dart';

import 'package:loure/client/nip19/nip19.dart';
import 'package:loure/util/string_util.dart';

// ignore: must_be_immutable
class NameComponent extends StatefulWidget {
  String pubkey;
  Metadata? metadata;
  bool showNip05;
  double? fontSize;
  Color? fontColor;
  TextOverflow? textOverflow;
  int? maxLines;

  NameComponent({
    super.key,
    required this.pubkey,
    this.metadata,
    this.showNip05 = true,
    this.fontSize,
    this.fontColor,
    this.textOverflow,
    this.maxLines = 3,
  });

  @override
  State<StatefulWidget> createState() {
    return _NameComponent();
  }
}

class _NameComponent extends State<NameComponent> {
  @override
  Widget build(BuildContext context) {
    var themeData = Theme.of(context);
    // var mainColor = themeData.primaryColor;
    var textSize = themeData.textTheme.bodyMedium!.fontSize;
    var smallTextSize = themeData.textTheme.bodySmall!.fontSize;
    Color hintColor = themeData.hintColor;

    var metadata = widget.metadata;
    String nip19Name = Nip19.encodeSimplePubKey(widget.pubkey);
    String displayName = "";
    String name = "";
    if (widget.fontColor != null) {
      hintColor = widget.fontColor!;
    }

    if (metadata != null) {
      if (metadata.displayName != "") {
        displayName = metadata.displayName!;
        if (metadata.name != "") {
          name = metadata.name!;
        }
      } else if (metadata.name != "") {
        displayName = metadata.name!;
      }
    }

    List<InlineSpan> nameList = [];

    if (displayName == "") {
      displayName = nip19Name;
    }

    nameList.add(TextSpan(
      text: StringUtil.breakWord(displayName),
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: widget.fontSize ?? textSize,
        color: widget.fontColor,
      ),
    ));

    if (name != "") {
      nameList.add(WidgetSpan(
        child: Container(
          margin: const EdgeInsets.only(left: 2),
          child: Text(
            StringUtil.breakWord("@$name"),
            style: TextStyle(
              fontSize: smallTextSize,
              color: hintColor,
            ),
          ),
        ),
      ));
    }

    if (metadata != null) {
      nameList.add(
        WidgetSpan(
          child: Container(
            margin: const EdgeInsets.only(left: 3),
            child: Nip05ValidComponent(metadata: metadata),
          ),
        ),
      );
    }

    return Text.rich(
      TextSpan(children: nameList),
      maxLines: widget.maxLines,
      overflow: widget.textOverflow,
    );
  }
}
