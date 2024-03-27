import "package:flutter/material.dart";
import "package:loure/client/input.dart";
import "package:loure/client/nip51/bookmarks.dart";
import "package:loure/provider/list_provider.dart";
import "package:provider/provider.dart";

import "package:loure/component/content/content_link_pre_component.dart";
import "package:loure/component/cust_state.dart";
import "package:loure/component/event/event_quote_component.dart";
import "package:loure/util/platform_util.dart";
import "package:loure/util/router_util.dart";
import "package:loure/router/index/index_app_bar.dart";

class BookmarkRouter extends StatefulWidget {
  const BookmarkRouter({super.key});

  @override
  State<StatefulWidget> createState() {
    return _BookmarkRouter();
  }
}

class _BookmarkRouter extends CustState<BookmarkRouter> {
  @override
  Widget doBuild(final BuildContext context) {
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

    final main = Selector<BookmarkProvider, Bookmarks>(
        builder: (final context, final bookmarks, final child) {
      return TabBarView(
        children: [
          buildBookmarkItems(bookmarks.privateItems),
          buildBookmarkItems(bookmarks.publicItems),
        ],
      );
    }, selector: (final context, final provider) {
      return provider.bookmarks;
    });

    return DefaultTabController(
      length: 2,
      child: Scaffold(
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
            tabs: [
              Container(
                height: IndexAppBar.height,
                alignment: Alignment.center,
                child: Text(
                  "Private",
                  style: titleTextStyle,
                ),
              ),
              Container(
                height: IndexAppBar.height,
                alignment: Alignment.center,
                child: Text(
                  "Public",
                  style: titleTextStyle,
                ),
              )
            ],
          ),
        ),
        body: main,
      ),
    );
  }

  @override
  Future<void> onReady(final BuildContext context) async {}

  Widget buildBookmarkItems(final List<BookmarkItem> items) {
    return ListView.builder(
      itemBuilder: (final context, final index) {
        final item = items[items.length - index - 1];
        if (item.key == "r") {
          return ContentLinkPreComponent(
            link: item.value,
          );
        } else {
          return EventQuoteComponent(
            id: item.key == "e" ? item.value : null,
            aId: item.key == "a"
                ? AddressPointer.fromTag(["", item.value])
                : null,
          );
        }
      },
      itemCount: items.length,
    );
  }
}
