import "package:bot_toast/bot_toast.dart";
import "package:flutter/material.dart";
import "package:loure/util/string_util.dart";

import "package:loure/consts/base.dart";

class PollInputController {
  TextEditingController minValueController = TextEditingController();
  TextEditingController maxValueController = TextEditingController();
  List<TextEditingController> pollOptionControllers = [];

  void clear() {
    minValueController.clear();
    maxValueController.clear();
    pollOptionControllers = [];
  }

  List<List<String>> getTags() {
    List<List<String>> tags = [];
    final length = pollOptionControllers.length;
    for (var i = 0; i < length; i++) {
      final pollPotion = pollOptionControllers[i];
      tags.add(["poll_option", "$i", pollPotion.text]);
    }
    if (StringUtil.isNotBlank(maxValueController.text)) {
      tags.add(["value_maximum", maxValueController.text]);
    }
    if (StringUtil.isNotBlank(minValueController.text)) {
      tags.add(["value_minimum", minValueController.text]);
    }

    return tags;
  }

  bool checkInput(final BuildContext context) {
    if (StringUtil.isNotBlank(maxValueController.text)) {
      final num = int.tryParse(maxValueController.text);
      if (num == null) {
        BotToast.showText(text: "Number parse error");
        return false;
      }
    }
    if (StringUtil.isNotBlank(minValueController.text)) {
      final num = int.tryParse(minValueController.text);
      if (num == null) {
        BotToast.showText(text: "Number parse error");
        return false;
      }
    }

    for (final pollOptionController in pollOptionControllers) {
      if (StringUtil.isBlank(pollOptionController.text)) {
        BotToast.showText(text: "Input can not be null");
        return false;
      }
    }

    return true;
  }
}

// ignore: must_be_immutable
class PollInputComponent extends StatefulWidget {
  PollInputComponent({required this.pollInputController, super.key});
  PollInputController pollInputController;

  @override
  State<StatefulWidget> createState() {
    return _PollInputComponent();
  }
}

class _PollInputComponent extends State<PollInputComponent> {
  @override
  void initState() {
    super.initState();

    widget.pollInputController.pollOptionControllers
        .add(TextEditingController());
    widget.pollInputController.pollOptionControllers
        .add(TextEditingController());
  }

  @override
  Widget build(final BuildContext context) {
    final themeData = Theme.of(context);
    final mainColor = themeData.primaryColor;
    List<Widget> list = [];

    bool delAble = false;
    if (widget.pollInputController.pollOptionControllers.length > 2) {
      delAble = true;
    }

    for (final controller in widget.pollInputController.pollOptionControllers) {
      Widget inputWidget = TextField(
        controller: controller,
        decoration: const InputDecoration(
          hintText: "poll option info",
        ),
      );
      if (delAble) {
        inputWidget = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(child: inputWidget),
            IconButton(
                onPressed: () {
                  delPollOption(controller);
                },
                icon: const Icon(Icons.delete)),
          ],
        );
      }

      list.add(Container(
        child: inputWidget,
      ));
    }

    list.add(Container(
      margin: const EdgeInsets.only(top: Base.BASE_PADDING),
      child: InkWell(
        onTap: addPollOption,
        child: Container(
          height: 36,
          color: mainColor,
          alignment: Alignment.center,
          child: const Text(
            "add poll option",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    ));

    list.add(Row(
      children: [
        Expanded(
            child: TextField(
          controller: widget.pollInputController.minValueController,
          decoration: const InputDecoration(
            hintText: "min zap num",
          ),
          keyboardType: TextInputType.number,
        )),
        Container(
          width: Base.BASE_PADDING,
        ),
        Expanded(
            child: TextField(
          controller: widget.pollInputController.maxValueController,
          decoration: const InputDecoration(
            hintText: "max zap num",
          ),
          keyboardType: TextInputType.number,
        )),
      ],
    ));

    return Container(
      padding: const EdgeInsets.only(
        left: Base.BASE_PADDING,
        right: Base.BASE_PADDING,
        bottom: Base.BASE_PADDING,
      ),
      width: double.maxFinite,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: list,
      ),
    );
  }

  void addPollOption() {
    widget.pollInputController.pollOptionControllers
        .add(TextEditingController());
    setState(() {});
  }

  void delPollOption(final TextEditingController controller) {
    widget.pollInputController.pollOptionControllers.remove(controller);
    setState(() {});
  }
}
