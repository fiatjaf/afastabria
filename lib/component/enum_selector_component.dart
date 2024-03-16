import "package:flutter/material.dart";

import "package:loure/consts/base.dart";
import "package:loure/consts/base_consts.dart";
import "package:loure/util/router_util.dart";

class EnumSelectorComponent extends StatelessWidget {
  EnumSelectorComponent({
    required this.list,
    super.key,
    this.enumItemBuild,
  });
  final List<EnumObj> list;

  Widget Function(BuildContext, EnumObj)? enumItemBuild;

  static Future<EnumObj?> show(
      final BuildContext context, final List<EnumObj> list) async {
    return await showDialog<EnumObj?>(
      context: context,
      builder: (final context) {
        return EnumSelectorComponent(
          list: list,
        );
      },
    );
  }

  @override
  Widget build(final BuildContext context) {
    final themeData = Theme.of(context);
    final Color cardColor = themeData.cardColor;
    final maxHeight = MediaQuery.of(context).size.height;

    List<Widget> widgets = [];
    for (var i = 0; i < list.length; i++) {
      final enumObj = list[i];
      if (enumItemBuild != null) {
        widgets.add(enumItemBuild!(context, enumObj));
      } else {
        widgets.add(EnumSelectorItemComponent(
          enumObj: enumObj,
          isLast: i == list.length - 1,
        ));
      }
    }

    final Widget main = Container(
      width: double.infinity,
      padding: const EdgeInsets.only(
        left: Base.BASE_PADDING,
        right: Base.BASE_PADDING,
        top: Base.BASE_PADDING_HALF,
        bottom: Base.BASE_PADDING_HALF,
      ),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(15)),
        color: cardColor,
      ),
      constraints: BoxConstraints(
        maxHeight: maxHeight * 0.8,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: widgets,
        ),
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
}

class EnumSelectorItemComponent extends StatelessWidget {
  EnumSelectorItemComponent({
    required this.enumObj,
    super.key,
    this.isLast = false,
    this.onTap,
    this.color,
  });
  static const double HEIGHT = 44;

  final EnumObj enumObj;

  final bool isLast;

  Function(EnumObj)? onTap;

  Color? color;

  @override
  Widget build(final BuildContext context) {
    final themeData = Theme.of(context);
    final dividerColor = themeData.dividerColor;

    final Widget main = Container(
      padding: const EdgeInsets.only(
          left: Base.BASE_PADDING + 5, right: Base.BASE_PADDING + 5),
      child: Text(enumObj.name),
    );

    return GestureDetector(
      onTap: () {
        if (onTap != null) {
          onTap!(enumObj);
        } else {
          RouterUtil.back(context, enumObj);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: color,
          border:
              isLast ? null : Border(bottom: BorderSide(color: dividerColor)),
        ),
        alignment: Alignment.center,
        height: HEIGHT,
        child: main,
      ),
    );
  }
}
