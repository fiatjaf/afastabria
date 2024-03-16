import "package:flutter/material.dart";
import "package:loure/component/tag_info_component.dart";
import "package:loure/consts/base.dart";

import "package:loure/client/nip02/cust_contact_list.dart";
import "package:loure/util/router_util.dart";

class FollowedTagsListRouter extends StatefulWidget {
  const FollowedTagsListRouter({super.key});

  @override
  State<StatefulWidget> createState() {
    return _FollowedTagsListRouter();
  }
}

class _FollowedTagsListRouter extends State<FollowedTagsListRouter> {
  CustContactList? contactList;

  @override
  Widget build(final BuildContext context) {
    if (contactList == null) {
      final arg = RouterUtil.routerArgs(context);
      if (arg != null) {
        contactList = arg as CustContactList;
      }
    }
    if (contactList == null) {
      RouterUtil.back(context);
      return Container();
    }

    final themeData = Theme.of(context);
    final titleFontSize = themeData.textTheme.bodyLarge!.fontSize;

    final tagList = contactList!.tagList().toList();

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
          "Followed Tags",
          style: TextStyle(
            fontSize: titleFontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 3,
          crossAxisSpacing: Base.BASE_PADDING_HALF,
        ),
        itemBuilder: (final context, final index) {
          final tag = tagList[index];

          return TagInfoComponent(
            tag: tag,
            jumpable: true,
          );
        },
        itemCount: tagList.length,
      ),
    );
  }
}
