import "dart:async";
import "dart:io";

import "package:bot_toast/bot_toast.dart";
import "package:flutter/material.dart";
import "package:flutter_inapp_purchase/flutter_inapp_purchase.dart";
import "package:loure/component/cust_state.dart";
import "package:loure/component/pc_router_fake.dart";
import "package:loure/consts/base_consts.dart";
import "package:loure/provider/pc_router_fake_provider.dart";
import "package:loure/util/platform_util.dart";
import "package:loure/util/string_util.dart";
import "package:provider/provider.dart";

import "package:loure/main.dart";
import "package:loure/provider/index_provider.dart";
import "package:loure/util/auth_util.dart";
import "package:loure/router/dm/dm_router.dart";
import "package:loure/router/edit/editor_router.dart";
import "package:loure/router/follow/follow_index_router.dart";
import "package:loure/router/globals/globals_index_router.dart";
import "package:loure/router/login/login_router.dart";
import "package:loure/router/search/search_router.dart";
import "package:loure/router/index/index_app_bar.dart";
import "package:loure/router/index/index_bottom_bar.dart";
import "package:loure/router/index/index_drawer_content.dart";

// ignore: must_be_immutable
class IndexRouter extends StatefulWidget {
  IndexRouter({required this.reload, super.key});
  Function reload;

  @override
  State<StatefulWidget> createState() {
    return _IndexRouter();
  }
}

class _IndexRouter extends CustState<IndexRouter>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  static double PC_MAX_COLUMN_0 = 200;
  static double PC_MAX_COLUMN_1 = 550;

  late TabController followTabController;
  late TabController globalsTabController;
  late TabController dmTabController;

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
        TabController(initialIndex: followInitTab, length: 3, vsync: this);
    globalsTabController =
        TabController(initialIndex: globalsInitTab, length: 3, vsync: this);
    dmTabController = TabController(length: 2, vsync: this);

    if (!PlatformUtil.isPC() && !PlatformUtil.isWeb()) {
      try {
        asyncInitState();
      } catch (e) {
        print(e);
      }
    }
  }

  @override
  void didChangeAppLifecycleState(final AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.resumed:
        print("AppLifecycleState.resumed");
        break;
      case AppLifecycleState.inactive:
        print("AppLifecycleState.inactive");
        break;
      case AppLifecycleState.detached:
        print("AppLifecycleState.detached");
        break;
      case AppLifecycleState.paused:
        print("AppLifecycleState.paused");
        break;
      case AppLifecycleState.hidden:
        print("AppLifecycleState.hidden");
        break;
    }
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
              "Posts & Replies",
              textAlign: TextAlign.center,
              style: titleTextStyle,
            ),
          ),
          Container(
            height: IndexAppBar.height,
            alignment: Alignment.center,
            child: Text(
              "Mentions",
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
          Container(
            height: IndexAppBar.height,
            alignment: Alignment.center,
            child: Text(
              "Topics",
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
    } else if (indexProvider.currentTap == 3) {
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
              "DMs",
              style: themeData.appBarTheme.titleTextStyle,
            ),
          ),
          Container(
            height: IndexAppBar.height,
            alignment: Alignment.center,
            child: Text(
              "Request",
              style: themeData.appBarTheme.titleTextStyle,
            ),
          ),
        ],
        controller: dmTabController,
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
          DMRouter(
            tabController: dmTabController,
          ),
          // NoticeRouter(),
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
            child: Selector<PcRouterFakeProvider, List<RouterFakeInfo>>(
              builder: (final context, final infos, final child) {
                if (infos.isEmpty) {
                  return const Center(
                    child: Text("There should be a universe here."),
                  );
                }

                final List<Widget> pages = [];
                for (final info in infos) {
                  if (StringUtil.isNotBlank(info.routerPath) &&
                      routes[info.routerPath] != null) {
                    final builder = routes[info.routerPath];
                    if (builder != null) {
                      pages.add(PcRouterFake(
                        info: info,
                        child: builder(context),
                      ));
                    }
                  } else if (info.buildContent != null) {
                    pages.add(PcRouterFake(
                      info: info,
                      child: info.buildContent!(context),
                    ));
                  }
                }

                return IndexedStack(
                  index: pages.length - 1,
                  children: pages,
                );
              },
              selector: (final context, final provider) {
                return provider.routerFakeInfos;
              },
              shouldRebuild: (final previous, final next) {
                if (previous != next) {
                  return true;
                }
                return false;
              },
            ),
          )
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
    AuthUtil.authenticate(context, "Please_authenticate_to_use_app")
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

  StreamSubscription? _purchaseUpdatedSubscription;

  void asyncInitState() async {
    await FlutterInappPurchase.instance.initialize();
    _purchaseUpdatedSubscription =
        FlutterInappPurchase.purchaseUpdated.listen((final productItem) async {
      if (productItem == null) {
        return;
      }

      try {
        if (Platform.isAndroid) {
          await FlutterInappPurchase.instance.finishTransaction(productItem);
        } else if (Platform.isIOS) {
          await FlutterInappPurchase.instance
              .finishTransactionIOS(productItem.transactionId!);
        }
      } catch (e) {
        print(e);
      }
      print("purchase-updated: $productItem");
      BotToast.showText(text: "Thanks yours coffee!");
    });
  }

  @override
  void dispose() async {
    super.dispose();
    WidgetsBinding.instance.removeObserver(this);
    if (!PlatformUtil.isPC() && !PlatformUtil.isWeb()) {
      if (_purchaseUpdatedSubscription != null) {
        _purchaseUpdatedSubscription!.cancel();
        _purchaseUpdatedSubscription = null;
      }
      await FlutterInappPurchase.instance.finalize();
    }
  }
}
