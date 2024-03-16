import "package:flutter/material.dart";
import "package:loure/router/follow/mention_me_router.dart";

import "package:loure/router/follow/follow_posts_router.dart";
import "package:loure/router/follow/follow_router.dart";

class FollowIndexRouter extends StatefulWidget {
  FollowIndexRouter({required this.tabController, super.key});
  TabController tabController;

  @override
  State<StatefulWidget> createState() {
    return _FollowIndexRouter();
  }
}

class _FollowIndexRouter extends State<FollowIndexRouter> {
  @override
  Widget build(final BuildContext context) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: TabBarView(
        controller: widget.tabController,
        children: const [
          FollowPostsRouter(),
          FollowRouter(),
          MentionMeRouter(),
        ],
      ),
    );
  }
}
