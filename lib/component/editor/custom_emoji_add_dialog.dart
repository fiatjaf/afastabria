import "dart:developer";

import "package:bot_toast/bot_toast.dart";
import "package:flutter/material.dart";
import "package:loure/data/custom_emoji.dart";

import "package:loure/client/upload/uploader.dart";
import "package:loure/consts/base.dart";
import "package:loure/main.dart";
import "package:loure/util/router_util.dart";
import "package:loure/util/string_util.dart";
import "package:loure/component/content/content_custom_emoji_component.dart";

class CustomEmojiAddDialog extends StatefulWidget {
  const CustomEmojiAddDialog({super.key});

  @override
  State<StatefulWidget> createState() {
    return _CustomEmojiAddDialog();
  }

  static Future<CustomEmoji?> show(final BuildContext context) async {
    return await showDialog<CustomEmoji>(
      context: context,
      builder: (final context) {
        return const CustomEmojiAddDialog();
      },
    );
  }
}

class _CustomEmojiAddDialog extends State<CustomEmojiAddDialog> {
  late TextEditingController controller;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController();
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
        "Add Custom Emoji",
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
          hintText: "Input Custom Emoji Name",
          border: OutlineInputBorder(borderSide: BorderSide(width: 1)),
        ),
      ),
    ));

    List<Widget> imageWidgetList = [
      GestureDetector(
        onTap: pickPicture,
        child: const Icon(Icons.image),
      )
    ];
    if (StringUtil.isNotBlank(filepath)) {
      imageWidgetList.add(ContentCustomEmojiComponent(imagePath: filepath!));
    }

    list.add(Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: imageWidgetList,
    ));

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

  Future<void> pickPicture() async {
    filepath = await Uploader.pick(context);
    setState(() {});
  }

  static const _regExp = r"^[ZA-ZZa-z0-9_]+$";

  String? filepath;

  Future<void> _onConfirm() async {
    final text = controller.text;
    if (StringUtil.isBlank(text)) {
      BotToast.showText(text: "Input can not be null");
      return;
    }

    if (RegExp(_regExp).firstMatch(text) == null) {
      BotToast.showText(text: "Input parse error");
      return;
    }

    final cancel = BotToast.showLoading();
    try {
      final imagePath = await Uploader.upload(
        filepath!,
        imageService: settingProvider.imageService,
      );
      log("$text $imagePath");

      if (StringUtil.isBlank(imagePath)) {
        BotToast.showText(text: "Upload fail.");
        return;
      }

      filepath = imagePath;
    } finally {
      cancel.call();
    }

    if (filepath != null) {
      RouterUtil.back(context, CustomEmoji(text, filepath!));
    }
  }
}
