import "package:flutter/material.dart";
import "package:loure/router/filter/filter_block_component.dart";
import "package:loure/router/filter/filter_dirtyword_component.dart";

import "package:loure/util/platform_util.dart";
import "package:loure/util/router_util.dart";
import "package:loure/router/index/index_app_bar.dart";

class FilterRouter extends StatefulWidget {
  const FilterRouter({super.key});

  @override
  State<StatefulWidget> createState() {
    return FilterRouterState();
  }
}

class FilterRouterState extends State<FilterRouter>
    with SingleTickerProviderStateMixin {
  late TabController tabController;

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(final BuildContext context) {
    final themeData = Theme.of(context);
    final titleTextColor = themeData.appBarTheme.titleTextStyle!.color;
    final titleTextStyle = TextStyle(
      fontWeight: FontWeight.bold,
      color: titleTextColor,
    );
    Color? indicatorColor = titleTextColor;
    if (PlatformUtil.isTableMode()) {
      indicatorColor = themeData.primaryColor;
    }

    return Scaffold(
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () {
            RouterUtil.back(context);
          },
          child: Icon(
            Icons.arrow_back_ios,
            color: themeData.appBarTheme.titleTextStyle!.color,
          ),
        ),
        title: TabBar(
          indicatorColor: indicatorColor,
          indicatorWeight: 3,
          controller: tabController,
          tabs: [
            Container(
              height: IndexAppBar.height,
              alignment: Alignment.center,
              child: Text(
                "Blocks",
                style: titleTextStyle,
              ),
            ),
            Container(
              height: IndexAppBar.height,
              alignment: Alignment.center,
              child: Text(
                "Dirtywords",
                style: titleTextStyle,
              ),
            )
          ],
        ),
        actions: [
          Container(
            width: 50,
            // height: 10,
            // color: Colors.red,
          ),
        ],
      ),
      body: TabBarView(
        controller: tabController,
        children: const [
          FilterBlockComponent(),
          FilterDirtywordComponent(),
        ],
      ),
    );
  }
}
