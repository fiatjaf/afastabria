import 'package:flutter/material.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/util/platform_util.dart';

import 'package:nostrmo/consts/base.dart';
import 'package:nostrmo/router/index/index_app_bar.dart';
import 'package:nostrmo/util/router_util.dart';
import 'package:nostrmo/util/string_util.dart';
import 'package:nostrmo/component/editor/text_input_dialog_inner_component.dart';

class TextInputAndSearchDialog extends StatefulWidget {
  String searchTabName;

  String title;

  String? hintText;

  String? value;

  Widget searchWidget;

  bool Function(BuildContext, String)? valueCheck;

  TextInputAndSearchDialog(
    this.searchTabName,
    this.title,
    this.searchWidget, {super.key, 
    this.hintText,
    this.value,
    this.valueCheck,
  });

  static Future<String?> show(BuildContext context, String searchTabName,
      String title, Widget searchWidget,
      {String? value,
      String? hintText,
      bool Function(BuildContext, String)? valueCheck}) async {
    return await showDialog<String>(
        context: context,
        builder: (context) {
          return TextInputAndSearchDialog(
            searchTabName,
            StringUtil.breakWord(title),
            searchWidget,
            hintText: hintText,
            value: value,
            valueCheck: valueCheck,
          );
        });
  }

  @override
  State<StatefulWidget> createState() {
    return _TextInputAndSearchDialog();
  }
}

class _TextInputAndSearchDialog extends State<TextInputAndSearchDialog>
    with SingleTickerProviderStateMixin {
  late TabController tabController;

  @override
  void initState() {
    super.initState();
    tabController = TabController(initialIndex: 0, length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
        var themeData = Theme.of(context);
    var cardColro = themeData.cardColor;
    var mainColor = themeData.primaryColor;

    double mainHeight = 266;
    if (PlatformUtil.isTableMode()) {
      mainHeight = mediaDataCache.size.height / 2;
    }

    var textInputWidget = TextInputDialogInnerComponent(
      widget.title,
      hintText: widget.hintText,
      value: widget.value,
      valueCheck: widget.valueCheck,
    );

    List<Widget> list = [];
    list.add(Container(
      color: mainColor,
      child: TabBar(
        tabs: [
          Container(
            height: IndexAppBar.height,
            alignment: Alignment.center,
            child: Text(widget.searchTabName),
          ),
          Container(
            height: IndexAppBar.height,
            alignment: Alignment.center,
            child: const Text(
              "Input",
              textAlign: TextAlign.center,
            ),
          ),
        ],
        controller: tabController,
      ),
    ));
    list.add(SizedBox(
      height: mainHeight,
      width: double.infinity,
      child: TabBarView(
        controller: tabController,
        children: [
          widget.searchWidget,
          textInputWidget,
        ],
      ),
    ));

    var main = Container(
      color: cardColro,
      child: Column(
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
}
