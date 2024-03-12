import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:nostrmo/util/string_util.dart';

import '../../consts/base.dart';

class ZapGoalInputController {
  TextEditingController goalAmountController = TextEditingController();

  void clear() {
    goalAmountController.clear();
  }

  List<List<dynamic>> getTags() {
    List<List<dynamic>> tags = [];
    if (StringUtil.isNotBlank(goalAmountController.text)) {
      tags.add(["amount", goalAmountController.text]);
    }

    return tags;
  }

  bool checkInput(BuildContext context) {
    print("goal input call");
        if (StringUtil.isBlank(goalAmountController.text)) {
      print("checked is blank!");
      BotToast.showText(text: "Input can not be null");
      return false;
    }
    if (StringUtil.isNotBlank(goalAmountController.text)) {
      var num = int.tryParse(goalAmountController.text);
      if (num == null) {
        BotToast.showText(text: "Number parse error");
        return false;
      }
    }

    return true;
  }
}

class ZapGoalInputComponent extends StatefulWidget {
  ZapGoalInputController zapGoalInputController;

  ZapGoalInputComponent({required this.zapGoalInputController});

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
  Widget build(BuildContext context) {
        var themeData = Theme.of(context);
    var mainColor = themeData.primaryColor;
    List<Widget> list = [];

    Widget inputWidget = TextField(
      controller: widget.zapGoalInputController.goalAmountController,
      decoration: InputDecoration(
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
