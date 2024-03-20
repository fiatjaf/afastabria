import "package:flutter/material.dart";
import "package:loure/client/aid.dart";
import "package:loure/consts/router_path.dart";
import "package:loure/provider/contact_list_provider.dart";
import "package:provider/provider.dart";

import "package:loure/client/nip02/contact_list.dart";
import "package:loure/consts/base.dart";
import "package:loure/main.dart";
import "package:loure/util/router_util.dart";

class FollowedCommunitiesRouter extends StatefulWidget {
  const FollowedCommunitiesRouter({super.key});

  @override
  State<StatefulWidget> createState() {
    return _FollowedCommunitiesRouter();
  }
}

class _FollowedCommunitiesRouter extends State<FollowedCommunitiesRouter> {
  ContactList? contactList;

  @override
  Widget build(final BuildContext context) {
    if (contactList == null) {
      final arg = RouterUtil.routerArgs(context);
      if (arg != null) {
        contactList = arg as ContactList;
      }
    }
    if (contactList == null) {
      RouterUtil.back(context);
      return Container();
    }

    final themeData = Theme.of(context);
    final titleFontSize = themeData.textTheme.bodyLarge!.fontSize;
    final hintColor = themeData.hintColor;

    final communitiesList = [];

    final main = ListView.builder(
      itemBuilder: (final context, final index) {
        final id = AId.fromString(communitiesList[index]);
        if (id == null) {
          return Container();
        }

        final item = Container(
          padding: const EdgeInsets.only(
            left: Base.BASE_PADDING,
            right: Base.BASE_PADDING,
          ),
          child: Container(
              padding: const EdgeInsets.only(
                left: Base.BASE_PADDING,
                right: Base.BASE_PADDING,
                top: Base.BASE_PADDING,
                bottom: Base.BASE_PADDING,
              ),
              decoration: BoxDecoration(
                  border: Border(
                      bottom: BorderSide(
                color: hintColor,
              ))),
              child: Row(children: [
                Text(id.identifier),
                Expanded(child: Container()),
                Selector<ContactListProvider, bool>(
                    builder: (final context, final exist, final child) {
                  IconData iconData = Icons.star_border;
                  Color? color;
                  if (exist) {
                    iconData = Icons.star;
                    color = Colors.yellow;
                  }
                  return GestureDetector(
                    onTap: () {
                      if (exist) {
                        contactListProvider.removeCommunity(id.toTag());
                      } else {
                        contactListProvider.addCommunity(id.toTag());
                      }
                    },
                    child: Container(
                      margin:
                          const EdgeInsets.only(left: Base.BASE_PADDING_HALF),
                      child: Icon(
                        iconData,
                        color: color,
                      ),
                    ),
                  );
                }, selector: (final context, final provider) {
                  return provider.containCommunity(id.toTag());
                })
              ])),
        );

        return GestureDetector(
          onTap: () {
            RouterUtil.router(context, RouterPath.COMMUNITY_DETAIL, id);
          },
          child: item,
        );
      },
      itemCount: communitiesList.length,
    );

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
        title: Text(
          "Followed Communities",
          style: TextStyle(
            fontSize: titleFontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Container(
        child: main,
      ),
    );
  }
}
