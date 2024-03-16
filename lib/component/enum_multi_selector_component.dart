import "package:flutter/material.dart";
import "package:loure/component/enum_selector_component.dart";
import "package:loure/main.dart";
import "package:loure/util/router_util.dart";

import "package:loure/consts/base_consts.dart";

class EnumMultiSelectorComponent extends StatefulWidget {
  const EnumMultiSelectorComponent({
    required this.list,
    required this.values,
    super.key,
  });
  final List<EnumObj> list;

  final List<EnumObj> values;

  static Future<List<EnumObj>?> show(final BuildContext context,
      final List<EnumObj> list, final List<EnumObj> values) async {
    return await showDialog<List<EnumObj>?>(
      context: context,
      builder: (final context) {
        return EnumMultiSelectorComponent(
          list: list,
          values: values,
        );
      },
    );
  }

  @override
  State<StatefulWidget> createState() {
    return _EnumMultiSelectorComponent();
  }
}

class _EnumMultiSelectorComponent extends State<EnumMultiSelectorComponent> {
  double BTN_WIDTH = 50;

  late List<EnumObj> values;

  @override
  void initState() {
    super.initState();
    values = widget.values;
  }

  @override
  Widget build(final BuildContext context) {
    final themeData = Theme.of(context);
    final mainColor = themeData.primaryColor;
    final btnTextColor = themeData.appBarTheme.titleTextStyle!.color;

    return Stack(
      alignment: Alignment.center,
      children: [
        EnumSelectorComponent(list: widget.list, enumItemBuild: enumItemBuild),
        Positioned(
          bottom: mediaDataCache.size.height / 20,
          child: GestureDetector(
            onTap: () {
              return RouterUtil.back(context, values);
            },
            child: Container(
              width: BTN_WIDTH,
              height: BTN_WIDTH,
              decoration: BoxDecoration(
                color: mainColor,
                borderRadius: BorderRadius.circular(BTN_WIDTH / 2),
              ),
              child: Icon(
                Icons.done,
                color: btnTextColor,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget enumItemBuild(final BuildContext context, final EnumObj enumObj) {
    bool isLast = false;
    if (enumObj.value == widget.list.last.value) {
      isLast = true;
    }

    bool exist = false;
    for (final value in values) {
      if (value.value == enumObj.value) {
        exist = true;
      }
    }

    return EnumSelectorItemComponent(
      enumObj: enumObj,
      isLast: isLast,
      onTap: onTap,
      color: exist ? Colors.blue.withOpacity(0.2) : null,
    );
  }

  void onTap(final EnumObj enumObj) {
    bool exist = false;
    for (final value in values) {
      if (value.value == enumObj.value) {
        exist = true;
      }
    }

    if (exist) {
      values.removeWhere((final element) {
        return element.value == enumObj.value;
      });
    } else {
      values.add(enumObj);
    }

    setState(() {});
  }
}
