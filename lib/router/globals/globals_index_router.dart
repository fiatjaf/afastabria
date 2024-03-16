import "package:flutter/material.dart";

import "package:loure/router/globals/events/globals_events_router.dart";
import "package:loure/router/globals/tags/globals_tags_router.dart";
import "package:loure/router/globals/users/globals_users_router.dart";

// ignore: must_be_immutable
class GlobalsIndexRouter extends StatefulWidget {
  GlobalsIndexRouter({required this.tabController, super.key});
  TabController tabController;

  @override
  State<StatefulWidget> createState() {
    return _GlobalsIndexRouter();
  }
}

class _GlobalsIndexRouter extends State<GlobalsIndexRouter> {
  @override
  Widget build(final BuildContext context) {
    return TabBarView(
      controller: widget.tabController,
      children: const [
        GlobalsEventsRouter(),
        GlobalsUsersRouter(),
        GlobalsTagsRouter(),
      ],
    );
  }
}
