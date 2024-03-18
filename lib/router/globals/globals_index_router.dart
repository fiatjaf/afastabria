import "package:flutter/material.dart";

import "package:loure/router/globals/events/globals_events_router.dart";
import "package:loure/router/globals/users/globals_users_router.dart";

class GlobalsIndexRouter extends StatelessWidget {
  const GlobalsIndexRouter({required this.tabController, super.key});

  final TabController tabController;

  @override
  Widget build(final BuildContext context) {
    return TabBarView(
      controller: this.tabController,
      children: const [
        GlobalsEventsRouter(),
        GlobalsUsersRouter(),
      ],
    );
  }
}
