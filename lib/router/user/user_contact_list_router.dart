import 'package:flutter/material.dart';

import 'package:nostrmo/client/nip02/cust_contact_list.dart';
import 'package:nostrmo/util/router_util.dart';
import 'package:nostrmo/router/user/user_contact_list_component.dart';

class UserContactListRouter extends StatefulWidget {
  const UserContactListRouter({super.key});

  @override
  State<StatefulWidget> createState() {
    return _UserContactListRouter();
  }
}

class _UserContactListRouter extends State<UserContactListRouter> {
  CustContactList? contactList;

  @override
  Widget build(BuildContext context) {
    
    if (contactList == null) {
      var arg = RouterUtil.routerArgs(context);
      if (arg != null) {
        contactList = arg as CustContactList;
      }
    }
    if (contactList == null) {
      RouterUtil.back(context);
      return Container();
    }
    var themeData = Theme.of(context);
    var titleFontSize = themeData.textTheme.bodyLarge!.fontSize;

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
          "Following",
          style: TextStyle(
            fontSize: titleFontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: UserContactListComponent(contactList: contactList!),
    );
  }
}
