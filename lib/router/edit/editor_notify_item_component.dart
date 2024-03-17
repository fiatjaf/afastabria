import "package:flutter/material.dart";

import "package:loure/data/metadata.dart";
import "package:loure/main.dart";
import "package:loure/component/simple_name_component.dart";
import "package:loure/consts/base.dart";

class EditorNotifyItem {
  EditorNotifyItem({required this.pubkey, this.selected = true});
  String pubkey;
  bool selected;
}

class EditorNotifyItemComponent extends StatefulWidget {
  const EditorNotifyItemComponent({required this.item, super.key});
  final EditorNotifyItem item;

  @override
  State<StatefulWidget> createState() {
    return EditorNotifyItemComponentState();
  }
}

class EditorNotifyItemComponentState extends State<EditorNotifyItemComponent> {
  @override
  Widget build(final BuildContext context) {
    final themeData = Theme.of(context);
    final mainColor = themeData.primaryColor;
    final textColor = themeData.appBarTheme.titleTextStyle!.color;

    List<Widget> list = [];
    list.add(
      FutureBuilder(
        future: metadataLoader.load(widget.item.pubkey),
        initialData: Metadata.blank(widget.item.pubkey),
        builder: (final context, final snapshot) {
          final String name = SimpleNameComponent.getSimpleName(
              widget.item.pubkey, snapshot.data);
          return Text(
            name,
            style: TextStyle(color: textColor),
          );
        },
      ),
    );

    list.add(SizedBox(
      width: 24,
      height: 24,
      child: Checkbox(
        value: widget.item.selected,
        onChanged: (final value) {
          setState(() {
            widget.item.selected = !widget.item.selected;
          });
        },
        side: BorderSide(color: textColor!.withOpacity(0.6), width: 2),
      ),
    ));

    return Container(
      decoration: BoxDecoration(
        color: mainColor.withOpacity(0.65),
        borderRadius: BorderRadius.circular(15),
      ),
      padding: const EdgeInsets.only(
        left: Base.BASE_PADDING,
        right: Base.BASE_PADDING,
        top: Base.BASE_PADDING_HALF / 2,
        bottom: Base.BASE_PADDING_HALF / 2,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: list,
      ),
    );
  }
}
