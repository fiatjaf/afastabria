import "package:bot_toast/bot_toast.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:loure/client/nip19/nip19.dart";
import "package:loure/main.dart";
import "package:loure/provider/filter_provider.dart";
import "package:provider/provider.dart";

import "package:loure/consts/base.dart";

class FilterBlockComponent extends StatefulWidget {
  const FilterBlockComponent({super.key});

  @override
  State<StatefulWidget> createState() {
    return _FilterBlockComponent();
  }
}

class _FilterBlockComponent extends State<FilterBlockComponent> {
  @override
  Widget build(final BuildContext context) {
    final filterProvider = Provider.of<FilterProvider>(context);
    final blockMap = filterProvider.blocks;
    final blocks = blockMap.keys.toList();
    // print(blocks);
    return Container(
      child: ListView.builder(
        itemBuilder: (final context, final index) {
          final pubkey = blocks[index];
          return FilterBlockItemComponent(pubkey: pubkey);
        },
        itemCount: blocks.length,
      ),
    );
  }
}

class FilterBlockItemComponent extends StatelessWidget {
  FilterBlockItemComponent({required this.pubkey, super.key});
  String pubkey;

  @override
  Widget build(final BuildContext context) {
    final themeData = Theme.of(context);
    final cardColor = themeData.cardColor;

    final nip19Pubkey = Nip19.encodePubKey(pubkey);
    return GestureDetector(
      onTap: () {
        Clipboard.setData(ClipboardData(text: nip19Pubkey)).then((final _) {
          BotToast.showText(text: "key has been copy!");
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: Base.BASE_PADDING_HALF),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.all(Base.BASE_PADDING),
        child: Row(children: [
          Expanded(child: Text(nip19Pubkey)),
          GestureDetector(
            onTap: delBlock,
            child: Container(
              margin: const EdgeInsets.only(left: Base.BASE_PADDING_HALF),
              child: const Icon(
                Icons.delete,
              ),
            ),
          )
        ]),
      ),
    );
  }

  void delBlock() {
    filterProvider.removeBlock(pubkey);
  }
}
