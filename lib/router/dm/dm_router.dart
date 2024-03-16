import "package:flutter/material.dart";

import "package:loure/client/nip04/nip04.dart";
import "package:loure/main.dart";
import "package:loure/router/dm/dm_known_list_router.dart";
import "package:loure/router/dm/dm_unknown_list_router.dart";

// ignore: must_be_immutable
class DMRouter extends StatefulWidget {
  DMRouter({required this.tabController, super.key});
  TabController tabController;

  @override
  State<StatefulWidget> createState() {
    return _DMRouter();
  }
}

class _DMRouter extends State<DMRouter> {
  @override
  Widget build(final BuildContext context) {
    final themeData = Theme.of(context);
    final agreement = NIP04.getAgreement(nostr.privateKey);

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
