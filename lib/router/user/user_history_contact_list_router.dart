import "package:flutter/material.dart";
import "package:loure/main.dart";

import "package:loure/client/nip02/cust_contact_list.dart";
import "package:loure/util/router_util.dart";
import "package:loure/router/user/user_contact_list_component.dart";

class UserHistoryContactListRouter extends StatefulWidget {
  const UserHistoryContactListRouter({super.key});

  @override
  State<StatefulWidget> createState() {
    return _UserHistoryContactListRouter();
  }
}

class _UserHistoryContactListRouter
    extends State<UserHistoryContactListRouter> {
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
    final titleTextColor = themeData.appBarTheme.titleTextStyle!.color;

    return Scaffold(
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () {
            RouterUtil.back(context);
          },
          child: Icon(
            Icons.arrow_back_ios,
            color: titleTextColor,
          ),
        ),
        title: Text(
          "Following",
          style: TextStyle(
            fontSize: titleFontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Container(
            child: TextButton(
              onPressed: doRecovery,
              style: const ButtonStyle(),
              child: Text(
                "Recovery",
                style: TextStyle(
                  color: titleTextColor,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
      body: UserContactListComponent(contactList: contactList!),
    );
  }

  void doRecovery() {
    contactListProvider.updateContacts(contactList!);
    RouterUtil.back(context);
  }
}
