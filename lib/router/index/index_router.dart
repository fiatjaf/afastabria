import "dart:async";

import "package:loure/router/routes.dart";
import "package:provider/provider.dart";
import "package:flutter/material.dart";

import "package:loure/component/cust_state.dart";
import "package:loure/consts/base_consts.dart";
import "package:loure/util/platform_util.dart";
import "package:loure/main.dart";
import "package:loure/provider/index_provider.dart";
import "package:loure/util/auth_util.dart";
import "package:loure/router/edit/editor_router.dart";
import "package:loure/router/follow/follow_index_router.dart";
import "package:loure/router/globals/globals_index_router.dart";
import "package:loure/router/login/login_router.dart";
import "package:loure/router/search/search_router.dart";
import "package:loure/router/index/index_app_bar.dart";
import "package:loure/router/index/index_bottom_bar.dart";
import "package:loure/router/index/index_drawer_content.dart";

class IndexRouter extends StatefulWidget {
  const IndexRouter({super.key});

  @override
  State<StatefulWidget> createState() {
    return IndexRouterState();
  }
}

class IndexRouterState extends CustState<IndexRouter>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  static double PC_MAX_COLUMN_0 = 200;
  static double PC_MAX_COLUMN_1 = 550;

  late TabController followTabController;
  late TabController globalsTabController;

  @override
  void initState() {
    super.initState();
    int followInitTab = 0;
    int globalsInitTab = 0;

    WidgetsBinding.instance.addObserver(this);

    if (settingProvider.defaultTab != null) {
      if (settingProvider.defaultIndex == 1) {
        globalsInitTab = settingProvider.defaultTab!;
      } else {
        followInitTab = settingProvider.defaultTab!;
      }
    }

    followTabController =
        TabController(initialIndex: followInitTab, length: 2, vsync: this);
    globalsTabController =
        TabController(initialIndex: globalsInitTab, length: 2, vsync: this);
  }

  @override
  Future<void> onReady(final BuildContext context) async {
    if (settingProvider.lockOpen == OpenStatus.OPEN && !unlock) {
      doAuth();
    } else {
      setState(() {
        unlock = true;
      });
    }

    settingProvider.addListener(() {
      this.setState(() {});
    });
  }

  bool unlock = false;

  @override
  Widget doBuild(final BuildContext context) {
    mediaDataCache.update(context);

    if (nostr.isEmpty()) {
      return const LoginRouter();
    }

    if (!unlock) {
      return const Scaffold();
    }

    final indexProvider = Provider.of<IndexProvider>(context);
    indexProvider.setFollowTabController(followTabController);
    indexProvider.setGlobalTabController(globalsTabController);
    final themeData = Theme.of(context);
    final mainColor = themeData.primaryColor;
    final titleTextColor = themeData.appBarTheme.titleTextStyle!.color;
    final titleTextStyle = TextStyle(
      fontWeight: FontWeight.bold,
      color: titleTextColor,
    );
    Color? indicatorColor = titleTextColor;
    if (PlatformUtil.isPC()) {
      indicatorColor = themeData.primaryColor;
    }

    Widget? appBarCenter;
    if (indexProvider.currentTap == 0) {
      appBarCenter = TabBar(
        indicatorColor: indicatorColor,
        indicatorWeight: 3,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerHeight: 0,
        tabs: [
          Container(
            height: IndexAppBar.height,
            alignment: Alignment.center,
            child: Text(
              "Posts",
              style: titleTextStyle,
            ),
          ),
          Container(
            height: IndexAppBar.height,
            alignment: Alignment.center,
            child: Text(
              "Inbox",
              style: titleTextStyle,
            ),
          ),
        ],
        controller: followTabController,
      );
    } else if (indexProvider.currentTap == 1) {
      appBarCenter = TabBar(
        indicatorColor: indicatorColor,
        indicatorWeight: 3,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerHeight: 0,
        tabs: [
          Container(
            height: IndexAppBar.height,
            alignment: Alignment.center,
            child: Text(
              "Notes",
              style: titleTextStyle,
            ),
          ),
          Container(
            height: IndexAppBar.height,
            alignment: Alignment.center,
            child: Text(
              "Users",
              style: titleTextStyle,
            ),
          ),
        ],
        controller: globalsTabController,
      );
    } else if (indexProvider.currentTap == 2) {
      appBarCenter = Center(
        child: Text(
          "Search",
          style: titleTextStyle,
        ),
      );
    }

    final addBtn = FloatingActionButton(
      onPressed: () {
        EditorRouter.open(context);
      },
      backgroundColor: mainColor,
      shape: const CircleBorder(),
      child: const Icon(
        Icons.add,
        color: Colors.white,
      ),
    );

    final mainCenterWidget = MediaQuery.removePadding(
      context: context,
      removeTop: true,
      child: Expanded(
          child: IndexedStack(
        index: indexProvider.currentTap,
        children: [
          FollowIndexRouter(
            tabController: followTabController,
          ),
          GlobalsIndexRouter(
            tabController: globalsTabController,
          ),
          const SearchRouter(),
        ],
      )),
    );

    final mainIndex = Column(
      children: [
        IndexAppBar(
          center: appBarCenter,
        ),
        mainCenterWidget,
      ],
    );

    if (PlatformUtil.isTableMode()) {
      final maxWidth = mediaDataCache.size.width;
      double column0Width = maxWidth * 1 / 5;
      double column1Width = maxWidth * 2 / 5;
      if (column0Width > PC_MAX_COLUMN_0) {
        column0Width = PC_MAX_COLUMN_0;
      }
      if (column1Width > PC_MAX_COLUMN_1) {
        column1Width = PC_MAX_COLUMN_1;
      }

      return Scaffold(
        // floatingActionButton: addBtn,
        // floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        body: Row(children: [
          SizedBox(
            width: column0Width,
            child: const IndexDrawerContnetComponnent(),
          ),
          Container(
            width: column1Width,
            margin: const EdgeInsets.only(
              // left: 1,
              right: 1,
            ),
            child: mainIndex,
          ),
          Expanded(
            child: StreamBuilder<Widget>(
              stream: internalRouter.stream,
              initialData: InternalRouter.base,
              builder: (final context, final snapshot) {
                return snapshot.data!;
              },
            ),
          ),
        ]),
      );
    } else {
      return Scaffold(
        body: mainIndex,
        floatingActionButton: addBtn,
        floatingActionButtonLocation:
            FloatingActionButtonLocation.miniCenterDocked,
        drawer: const Drawer(
          child: IndexDrawerContnetComponnent(),
        ),
        bottomNavigationBar: const IndexBottomBar(),
      );
    }
  }

  void doAuth() {
    AuthUtil.authenticate(context, "Please authenticate to use app")
        .then((final didAuthenticate) {
      if (didAuthenticate) {
        setState(() {
          unlock = true;
        });
      } else {
        doAuth();
      }
    });
  }

  @override
  void dispose() async {
    super.dispose();
    WidgetsBinding.instance.removeObserver(this);
  }
}
