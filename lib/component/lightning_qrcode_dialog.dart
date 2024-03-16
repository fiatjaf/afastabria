import "package:bot_toast/bot_toast.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:loure/util/string_util.dart";
import "package:pretty_qr_code/pretty_qr_code.dart";

import "package:loure/consts/base.dart";
import "package:loure/util/router_util.dart";

// ignore: must_be_immutable
class LightningQrcodeDialog extends StatefulWidget {
  LightningQrcodeDialog({
    required this.text,
    super.key,
    this.title,
  });
  String? title;

  String text;

  static Future<bool?> show(final BuildContext context, final String text,
      {final String? content, final String? title}) async {
    return await showDialog<bool>(
      context: context,
      builder: (final context) {
        return LightningQrcodeDialog(
          text: text,
          title: title,
        );
      },
    );
  }

  @override
  State<StatefulWidget> createState() {
    return _LightningQrcodeDialog();
  }
}

class _LightningQrcodeDialog extends State<LightningQrcodeDialog> {
  static const double IMAGE_WIDTH = 40;
  static const double QR_WIDTH = 200;

  @override
  Widget build(final BuildContext context) {
    final themeData = Theme.of(context);
    final Color cardColor = themeData.cardColor;
    final hintColor = themeData.hintColor;

    List<Widget> list = [];
    if (widget.title == null) {
      list.add(Container(
        child: const Text("Use lightning wallet scan and send sats."),
      ));
    } else {
      if (StringUtil.isNotBlank(widget.title)) {
        list.add(Container(
          child: const Text("Use lightning wallet scan and send sats."),
        ));
      }
    }
    list.add(Container(
      margin: const EdgeInsets.only(
        top: Base.BASE_PADDING,
        bottom: Base.BASE_PADDING,
        left: Base.BASE_PADDING_HALF,
        right: Base.BASE_PADDING_HALF,
      ),
      child: PrettyQr(
        data: widget.text,
        size: QR_WIDTH,
      ),
    ));
    list.add(GestureDetector(
      onTap: () {
        _doCopy(widget.text);
      },
      child: Container(
        padding: const EdgeInsets.all(Base.BASE_PADDING_HALF),
        margin: const EdgeInsets.only(
          left: 20,
          right: 20,
          bottom: Base.BASE_PADDING_HALF,
        ),
        decoration: BoxDecoration(
          color: hintColor.withOpacity(0.5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: SelectableText(
          widget.text,
          onTap: () {
            _doCopy(widget.text);
          },
        ),
      ),
    ));

    final main = Container(
      width: QR_WIDTH + 200,
      padding: const EdgeInsets.only(
        top: 20,
        bottom: 20,
      ),
      decoration: BoxDecoration(
        color: cardColor,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
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
            height: double.infinity,
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

  void _doCopy(final String text) {
    Clipboard.setData(ClipboardData(text: text)).then((final _) {
      BotToast.showText(text: "Copy_success");
    });
  }
}
