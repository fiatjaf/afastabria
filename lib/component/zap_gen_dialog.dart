import "package:bot_toast/bot_toast.dart";
import "package:flutter/material.dart";

import "package:loure/client/zap/zap_action.dart";
import "package:loure/consts/base.dart";
import "package:loure/util/router_util.dart";

// ignore: must_be_immutable
class ZapGenDialog extends StatefulWidget {
  ZapGenDialog(
      {required this.pubkey,
      required this.parentContext,
      super.key,
      this.eventId});
  String pubkey;

  String? eventId;

  BuildContext parentContext;

  static Future<void> show(final BuildContext context, final String pubkey,
      {final String? eventId}) async {
    return await showDialog<void>(
      context: context,
      builder: (final context) {
        return ZapGenDialog(
          pubkey: pubkey,
          eventId: eventId,
          parentContext: context,
        );
      },
    );
  }

  @override
  State<StatefulWidget> createState() {
    return _ZapGenDialog();
  }
}

class _ZapGenDialog extends State<ZapGenDialog> {
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
    final themeData = Theme.of(context);
    final Color cardColor = themeData.cardColor;
    final mainColor = themeData.primaryColor;
    final titleFontSize = themeData.textTheme.bodyLarge!.fontSize;

    List<Widget> list = [];

    list.add(Container(
      margin: const EdgeInsets.only(bottom: Base.BASE_PADDING),
      child: Text(
        "Input Sats num",
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

    // list.add(Expanded(child: Container()));

    list.add(Container(
      margin: const EdgeInsets.only(
        top: Base.BASE_PADDING,
        bottom: 6,
      ),
      child: Ink(
        decoration: BoxDecoration(color: mainColor),
        child: InkWell(
          onTap: _onConfirm,
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

    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.2),
      body: FocusScope(
        // autofocus: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            RouterUtil.back(context);
          },
          child: Container(
            width: double.infinity,
            // height: double.infinity,
            padding: const EdgeInsets.only(
              left: Base.BASE_PADDING,
              right: Base.BASE_PADDING,
            ),
            alignment: Alignment.center,
            child: GestureDetector(
              onTap: () {},
              child: main,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onConfirm() async {
    final text = controller.text;
    final num = int.tryParse(text);
    if (num == null) {
      BotToast.showText(text: "Number_parse_error");
      return;
    }

    final comment = commentController.text;
    RouterUtil.back(context);

    await ZapAction.handleZap(widget.parentContext, num, widget.pubkey,
        eventId: widget.eventId, comment: comment);
  }
}
