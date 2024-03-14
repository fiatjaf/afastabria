import 'package:flutter/material.dart';
import 'package:nostrmo/router/follow/mention_me_router.dart';

import 'package:nostrmo/router/follow/follow_posts_router.dart';
import 'package:nostrmo/router/follow/follow_router.dart';

class FollowIndexRouter extends StatefulWidget {
  TabController tabController;

  FollowIndexRouter({super.key, required this.tabController});

  @override
  State<StatefulWidget> createState() {
    return _FollowIndexRouter();
  }
}

class _FollowIndexRouter extends State<FollowIndexRouter> {
  @override
  Widget build(BuildContext context) {
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
