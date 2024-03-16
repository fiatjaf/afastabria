import "package:bot_toast/bot_toast.dart";
import "package:flutter/material.dart";
import "package:loure/util/string_util.dart";

import "package:loure/consts/base.dart";

class ZapGoalInputController {
  TextEditingController goalAmountController = TextEditingController();

  void clear() {
    goalAmountController.clear();
  }

  List<List<String>> getTags() {
    List<List<String>> tags = [];
    if (StringUtil.isNotBlank(goalAmountController.text)) {
      tags.add(["amount", goalAmountController.text]);
    }

    return tags;
  }

  bool checkInput(final BuildContext context) {
    print("goal input call");
    if (StringUtil.isBlank(goalAmountController.text)) {
      print("checked is blank!");
      BotToast.showText(text: "Input can not be null");
      return false;
    }
    if (StringUtil.isNotBlank(goalAmountController.text)) {
      final num = int.tryParse(goalAmountController.text);
      if (num == null) {
        BotToast.showText(text: "Number parse error");
        return false;
      }
    }

    return true;
  }
}

// ignore: must_be_immutable
class ZapGoalInputComponent extends StatefulWidget {
  ZapGoalInputComponent({required this.zapGoalInputController, super.key});
  ZapGoalInputController zapGoalInputController;

  @override
  State<StatefulWidget> createState() {
    return _ZapGoalInputComponent();
  }
}

class _ZapGoalInputComponent extends State<ZapGoalInputComponent> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(final BuildContext context) {
    // var themeData = Theme.of(context);
    // var mainColor = themeData.primaryColor;
    List<Widget> list = [];

    final Widget inputWidget = TextField(
      controller: widget.zapGoalInputController.goalAmountController,
      decoration: const InputDecoration(
        hintText: "Goal Amount In Sats",
      ),
    );

    list.add(Container(
      child: inputWidget,
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
}
