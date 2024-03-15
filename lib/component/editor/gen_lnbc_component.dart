import 'dart:developer';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:loure/client/zap/zap_action.dart';
import 'package:loure/consts/base.dart';
import 'package:loure/consts/router_path.dart';
import 'package:loure/data/metadata.dart';
import 'package:loure/main.dart';
import 'package:loure/provider/metadata_provider.dart';
import 'package:loure/util/router_util.dart';
import 'package:loure/util/string_util.dart';
import 'package:loure/component/content/content_str_link_component.dart';

class GenLnbcComponent extends StatefulWidget {
  const GenLnbcComponent({super.key});

  @override
  State<StatefulWidget> createState() {
    return _GenLnbcComponent();
  }
}

class _GenLnbcComponent extends State<GenLnbcComponent> {
  late TextEditingController controller;
  late TextEditingController commentController;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController();
    commentController = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    return Selector<MetadataProvider, Metadata?>(
      builder: (context, metadata, child) {
        var themeData = Theme.of(context);
        Color cardColor = themeData.cardColor;
        var mainColor = themeData.primaryColor;
        var titleFontSize = themeData.textTheme.bodyLarge!.fontSize;
        if (metadata == null ||
            (StringUtil.isBlank(metadata.lud06) &&
                StringUtil.isBlank(metadata.lud16))) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Lnurl and Lud16 can't found.",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(Base.BASE_PADDING),
                  child: ContentStrLinkComponent(
                    str: "Add now",
                    onTap: () async {
                      await RouterUtil.router(
                          context, RouterPath.PROFILE_EDITOR, metadata);
                      metadataProvider.update(nostr.publicKey);
                    },
                  ),
                )
              ],
            ),
          );
        }

        List<Widget> list = [];

        list.add(Container(
          margin: const EdgeInsets.only(bottom: Base.BASE_PADDING),
          child: Text(
            "Input Sats num to gen lightning invoice",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: titleFontSize,
            ),
          ),
        ));

        list.add(Container(
          margin: const EdgeInsets.only(bottom: Base.BASE_PADDING),
          child: TextField(
            controller: controller,
            minLines: 1,
            maxLines: 1,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: "Input Sats num",
              border: OutlineInputBorder(borderSide: BorderSide(width: 1)),
            ),
          ),
        ));

        list.add(Container(
          child: TextField(
            controller: commentController,
            minLines: 1,
            maxLines: 1,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: "${"Input Comment"} (${"Optional"})",
              border: OutlineInputBorder(borderSide: BorderSide(width: 1)),
            ),
          ),
        ));

        list.add(Expanded(child: Container()));

        list.add(Container(
          margin: const EdgeInsets.only(
            top: Base.BASE_PADDING,
            bottom: 6,
          ),
          child: Ink(
            decoration: BoxDecoration(color: mainColor),
            child: InkWell(
              onTap: () {
                _onConfirm(metadata.pubKey!);
              },
              highlightColor: mainColor.withOpacity(0.2),
              child: Container(
                color: mainColor,
                height: 40,
                alignment: Alignment.center,
                child: const Text(
                  "Confirm",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ));

        var main = Container(
          padding: const EdgeInsets.all(Base.BASE_PADDING),
          decoration: BoxDecoration(
            color: cardColor,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: list,
          ),
        );

        return main;
      },
      selector: (context, provider) {
        return provider.getMetadata(nostr.publicKey);
      },
    );
  }

  Future<void> _onConfirm(String pubkey) async {
    var text = controller.text;
    var num = int.tryParse(text);
    if (num == null) {
      BotToast.showText(text: "Number parse error");
      return;
    }

    var comment = commentController.text;
    log("comment $comment");
    var lnbcStr =
        await ZapAction.genInvoiceCode(context, num, pubkey, comment: comment);
    if (StringUtil.isNotBlank(lnbcStr)) {
      RouterUtil.back(context, lnbcStr);
    }
  }
}
