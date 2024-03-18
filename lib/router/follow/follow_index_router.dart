import "package:flutter/material.dart";

import "package:loure/router/follow/mention_me_router.dart";
import "package:loure/router/follow/follow_router.dart";

class FollowIndexRouter extends StatelessWidget {
  const FollowIndexRouter({required this.tabController, super.key});

  final TabController tabController;

  @override
  Widget build(final BuildContext context) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: TabBarView(
        controller: this.tabController,
        children: const [
          FollowRouter(),
          MentionMeRouter(),
        ],
      ),
    );
  }
}
