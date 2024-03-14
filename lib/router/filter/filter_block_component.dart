import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nostrmo/client/nip19/nip19.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/provider/filter_provider.dart';
import 'package:provider/provider.dart';

import 'package:nostrmo/consts/base.dart';

class FilterBlockComponent extends StatefulWidget {
  const FilterBlockComponent({super.key});

  @override
  State<StatefulWidget> createState() {
    return _FilterBlockComponent();
  }
}

class _FilterBlockComponent extends State<FilterBlockComponent> {
  @override
  Widget build(BuildContext context) {
    var filterProvider = Provider.of<FilterProvider>(context);
    var blockMap = filterProvider.blocks;
    var blocks = blockMap.keys.toList();
    // print(blocks);
    return Container(
      child: ListView.builder(
        itemBuilder: (context, index) {
          var pubkey = blocks[index];
          return FilterBlockItemComponent(pubkey: pubkey);
        },
        itemCount: blocks.length,
      ),
    );
  }
}

class FilterBlockItemComponent extends StatelessWidget {
  String pubkey;

  FilterBlockItemComponent({super.key, required this.pubkey});

  @override
  Widget build(BuildContext context) {
        var themeData = Theme.of(context);
    var cardColor = themeData.cardColor;

    var nip19Pubkey = Nip19.encodePubKey(pubkey);
    return GestureDetector(
      onTap: () {
        Clipboard.setData(ClipboardData(text: nip19Pubkey)).then((_) {
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
