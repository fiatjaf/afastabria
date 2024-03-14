import 'package:flutter/material.dart';

import 'package:nostrmo/client/nip04/nip04.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/router/dm/dm_known_list_router.dart';
import 'package:nostrmo/router/dm/dm_unknown_list_router.dart';

// ignore: must_be_immutable
class DMRouter extends StatefulWidget {
  TabController tabController;

  DMRouter({super.key, required this.tabController});

  @override
  State<StatefulWidget> createState() {
    return _DMRouter();
  }
}

class _DMRouter extends State<DMRouter> {
  @override
  Widget build(BuildContext context) {
    var themeData = Theme.of(context);
    var agreement = NIP04.getAgreement(nostr.privateKey);

    return Container(
      color: themeData.scaffoldBackgroundColor,
      child: TabBarView(
        controller: widget.tabController,
        children: [
          DMKnownListRouter(
            agreement: agreement,
          ),
          DMUnknownListRouter(
            agreement: agreement,
          ),
        ],
      ),
    );
  }
}
