import 'package:flutter/material.dart';

import 'package:nostrmo/router/globals/events/globals_events_router.dart';
import 'package:nostrmo/router/globals/tags/globals_tags_router.dart';
import 'package:nostrmo/router/globals/users/globals_users_router.dart';

// ignore: must_be_immutable
class GlobalsIndexRouter extends StatefulWidget {
  TabController tabController;

  GlobalsIndexRouter({super.key, required this.tabController});

  @override
  State<StatefulWidget> createState() {
    return _GlobalsIndexRouter();
  }
}

class _GlobalsIndexRouter extends State<GlobalsIndexRouter> {
  @override
  Widget build(BuildContext context) {
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
