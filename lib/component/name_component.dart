import "package:flutter/material.dart";
import "package:loure/component/nip05_valid_component.dart";
import "package:loure/client/metadata.dart";

class NameComponent extends StatelessWidget {
  const NameComponent({
    required this.pubkey,
    required this.metadata,
    super.key,
    this.showNip05 = true,
    this.fontSize,
    this.fontColor,
    this.textOverflow,
    this.maxLines = 3,
  });
  final String pubkey;
  final Metadata metadata;
  final bool showNip05;
  final double? fontSize;
  final Color? fontColor;
  final TextOverflow? textOverflow;
  final int? maxLines;

  @override
  Widget build(final BuildContext context) {
    final themeData = Theme.of(context);
    final textSize = themeData.textTheme.bodyMedium!.fontSize;

    final metadata = this.metadata;
    List<InlineSpan> nameList = [];

    nameList.add(TextSpan(
      text: metadata.shortName(),
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: this.fontSize ?? textSize,
        color: this.fontColor,
      ),
    ));

    nameList.add(
      WidgetSpan(
        child: Container(
          margin: const EdgeInsets.only(left: 3),
          child: Nip05ValidComponent(metadata: metadata),
        ),
      ),
    );

    return Text.rich(
      TextSpan(children: nameList),
      maxLines: this.maxLines,
      overflow: this.textOverflow,
    );
  }
}
