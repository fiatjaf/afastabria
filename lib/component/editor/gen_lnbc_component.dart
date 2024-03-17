import "package:bot_toast/bot_toast.dart";
import "package:flutter/material.dart";

import "package:loure/client/zap/zap_action.dart";
import "package:loure/consts/base.dart";
import "package:loure/consts/router_path.dart";
import "package:loure/data/metadata.dart";
import "package:loure/main.dart";
import "package:loure/util/router_util.dart";
import "package:loure/util/string_util.dart";
import "package:loure/component/content/content_str_link_component.dart";

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
  Widget build(final BuildContext context) {
    return FutureBuilder(
      future: metadataLoader.load(nostr.publicKey),
      initialData: Metadata.blank(nostr.publicKey),
      builder: (final context, final snapshot) {
        final metadata = snapshot.data!;

        final themeData = Theme.of(context);
        final Color cardColor = themeData.cardColor;
        final mainColor = themeData.primaryColor;
        final titleFontSize = themeData.textTheme.bodyLarge!.fontSize;
        if (metadata.lud06 == "" && metadata.lud16 == "") {
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
                          context, RouterPath.PROFILE_EDITOR);
                      metadataLoader.invalidate(nostr.publicKey);
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

        list.add(
          TextField(
            controller: commentController,
            minLines: 1,
            maxLines: 1,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: "${"Input Comment"} (${"Optional"})",
              border: OutlineInputBorder(borderSide: BorderSide(width: 1)),
            ),
          ),
        );

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
                _onConfirm(metadata.pubkey);
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

        final main = Container(
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
    );
  }

  Future<void> _onConfirm(final String pubkey) async {
    final text = controller.text;
    final num = int.tryParse(text);
    if (num == null) {
      BotToast.showText(text: "Number parse error");
      return;
    }

    final comment = commentController.text;
    print("comment $comment");
    final lnbcStr =
        await ZapAction.genInvoiceCode(context, num, pubkey, comment: comment);
    if (StringUtil.isNotBlank(lnbcStr)) {
      RouterUtil.back(context, lnbcStr);
    }
  }
}
