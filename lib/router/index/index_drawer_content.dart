import "package:provider/provider.dart";

import "package:flutter/material.dart";
import "package:loure/component/user/metadata_top_component.dart";
import "package:loure/consts/base.dart";
import "package:loure/consts/router_path.dart";
import "package:loure/provider/index_provider.dart";
import "package:loure/provider/webview_provider.dart";
import "package:loure/router/user/user_statistics_component.dart";
import "package:loure/util/platform_util.dart";
import "package:loure/util/router_util.dart";
import "package:loure/util/string_util.dart";
import "package:loure/data/metadata.dart";
import "package:loure/main.dart";
import "package:loure/router/edit/editor_router.dart";
import "package:loure/router/index/account_manager_component.dart";

class IndexDrawerContnetComponnent extends StatefulWidget {
  const IndexDrawerContnetComponnent({super.key});

  @override
  State<StatefulWidget> createState() {
    return _IndexDrawerContnetComponnent();
  }
}

class _IndexDrawerContnetComponnent
    extends State<IndexDrawerContnetComponnent> {
  ScrollController userStatisticscontroller = ScrollController();
  double profileEditBtnWidth = 40;

  @override
  Widget build(final BuildContext context) {
    final indexProvider = Provider.of<IndexProvider>(context);

    final pubkey = nostr.publicKey;
    final paddingTop = mediaDataCache.padding.top;
    final themeData = Theme.of(context);
    final mainColor = themeData.primaryColor;
    final cardColor = themeData.cardColor;
    final hintColor = themeData.hintColor;
    List<Widget> list = [];

    list.add(
      Stack(children: [
        FutureBuilder(
          future: metadataLoader.load(pubkey),
          initialData: Metadata.blank(pubkey),
          builder: (final context, final snapshot) {
            return MetadataTopComponent(
              pubkey: pubkey,
              metadata: snapshot.data,
              isLocal: true,
              jumpable: true,
            );
          },
        ),
        Positioned(
          top: paddingTop + Base.BASE_PADDING_HALF,
          right: Base.BASE_PADDING,
          child: Container(
            height: profileEditBtnWidth,
            width: profileEditBtnWidth,
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(profileEditBtnWidth / 2),
            ),
            child: IconButton(
              icon: const Icon(Icons.edit_square),
              onPressed: jumpToProfileEdit,
            ),
          ),
        ),
      ]),
    );

    list.add(GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragUpdate: (final detail) {
        userStatisticscontroller
            .jumpTo(userStatisticscontroller.offset - detail.delta.dx);
      },
      child: SingleChildScrollView(
        controller: userStatisticscontroller,
        scrollDirection: Axis.horizontal,
        child: UserStatisticsComponent(pubkey: pubkey),
      ),
    ));

    List<Widget> centerList = [];
    if (PlatformUtil.isTableMode()) {
      centerList.add(IndexDrawerItem(
        iconData: Icons.home,
        name: "Home",
        color: indexProvider.currentTap == 0 ? mainColor : null,
        onTap: () {
          indexProvider.setCurrentTap(0);
        },
        onDoubleTap: () {
          indexProvider.followScrollToTop();
        },
      ));
      centerList.add(IndexDrawerItem(
        iconData: Icons.public,
        name: "Globals",
        color: indexProvider.currentTap == 1 ? mainColor : null,
        onTap: () {
          indexProvider.setCurrentTap(1);
        },
        onDoubleTap: () {
          indexProvider.globalScrollToTop();
        },
      ));
      centerList.add(IndexDrawerItem(
        iconData: Icons.search,
        name: "Search",
        color: indexProvider.currentTap == 2 ? mainColor : null,
        onTap: () {
          indexProvider.setCurrentTap(2);
        },
      ));
      centerList.add(IndexDrawerItem(
        iconData: Icons.mail,
        name: "DMs",
        color: indexProvider.currentTap == 3 ? mainColor : null,
        onTap: () {
          indexProvider.setCurrentTap(3);
        },
      ));
    }

    centerList.add(IndexDrawerItem(
      iconData: Icons.block,
      name: "Filter",
      onTap: () {
        RouterUtil.router(context, RouterPath.FILTER);
      },
    ));

    centerList.add(IndexDrawerItem(
      iconData: Icons.cloud,
      name: "Relays",
      onTap: () {
        RouterUtil.router(context, RouterPath.RELAYS);
      },
    ));

    centerList.add(IndexDrawerItem(
      iconData: Icons.bookmarks,
      name: "Bookmarks",
      onTap: () {
        RouterUtil.router(context, RouterPath.BOOKMARK);
      },
    ));

    centerList.add(IndexDrawerItem(
      iconData: Icons.settings,
      name: "Settings",
      onTap: () {
        RouterUtil.router(context, RouterPath.SETTING);
      },
    ));

    if (!PlatformUtil.isPC()) {
      centerList.add(Selector<WebViewProvider, String?>(
          builder: (final context, final url, final child) {
        if (StringUtil.isBlank(url)) {
          return IndexDrawerItem(
            iconData: Icons.view_list,
            name: "Web Utils",
            onTap: () {
              RouterUtil.router(context, RouterPath.WEBUTILS);
            },
          );
        }

        return IndexDrawerItem(
          iconData: Icons.public,
          name: "Show web",
          onTap: () {
            webViewProvider.show();
          },
        );
      }, selector: (final context, final provider) {
        return provider.url;
      }));
    }

    centerList.add(IndexDrawerItem(
      iconData: Icons.key,
      name: "Key Backup",
      onTap: () {
        RouterUtil.router(context, RouterPath.KEY_BACKUP);
      },
    ));

    list.add(Expanded(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: centerList,
        ),
      ),
    ));

    if (PlatformUtil.isTableMode()) {
      list.add(IndexDrawerItem(
        iconData: Icons.add,
        name: "Add a Note",
        onTap: () {
          EditorRouter.open(context);
        },
      ));
    }

    list.add(IndexDrawerItem(
      iconData: Icons.account_box,
      name: "Account Manager",
      onTap: () {
        _showBasicModalBottomSheet(context);
      },
    ));
    // list.add(IndexDrawerItem(
    //   iconData: Icons.logout,
    //   name: "Sign out",
    //   onTap: signOut,
    // ));

    list.add(Container(
      margin: const EdgeInsets.only(top: Base.BASE_PADDING_HALF),
      padding: const EdgeInsets.only(
        left: Base.BASE_PADDING * 2,
        bottom: Base.BASE_PADDING,
        top: Base.BASE_PADDING,
      ),
      decoration: BoxDecoration(
          border: Border(
              top: BorderSide(
        width: 1,
        color: hintColor,
      ))),
      alignment: Alignment.centerLeft,
      child: Text("V ${Base.VERSION_NAME}"),
    ));

    return Column(
      children: list,
    );
  }

  void jumpToProfileEdit() async {
    RouterUtil.router(context, RouterPath.PROFILE_EDITOR);
  }

  void _showBasicModalBottomSheet(final context) async {
    showModalBottomSheet(
      isScrollControlled: false, // true 为 全屏
      context: context,
      builder: (final BuildContext context) {
        return const AccountManagerComponent();
      },
    );
  }
}

class IndexDrawerItem extends StatelessWidget {
  // bool borderTop;
  // bool borderBottom;

  const IndexDrawerItem({
    required this.iconData,
    required this.name,
    required this.onTap,
    super.key,
    this.color,
    this.onDoubleTap,
    // this.borderTop = true,
    // this.borderBottom = false,
  });
  final IconData iconData;
  final String name;
  final Function() onTap;
  final Function? onDoubleTap;
  final Color? color;

  @override
  Widget build(final BuildContext context) {
    List<Widget> list = [];

    list.add(Container(
      margin: const EdgeInsets.only(
        left: Base.BASE_PADDING * 2,
        right: Base.BASE_PADDING,
      ),
      child: Icon(
        iconData,
        color: color,
      ),
    ));

    list.add(Text(name, style: TextStyle(color: color)));

    return GestureDetector(
      onTap: onTap,
      onDoubleTap: () {
        if (onDoubleTap != null) {
          onDoubleTap!();
        }
      },
      behavior: HitTestBehavior.translucent,
      child: SizedBox(
        height: 34,
        // decoration: BoxDecoration(
        //   border: Border(
        //     top: borderTop ? borderSide : BorderSide.none,
        //     bottom: borderBottom ? borderSide : BorderSide.none,
        //   ),
        // ),
        child: Row(
          children: list,
        ),
      ),
    );
  }
}
