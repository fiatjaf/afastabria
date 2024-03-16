import "package:flutter/material.dart";
import "package:loure/component/keep_alive_cust_state.dart";
import "package:loure/component/new_notes_updated_component.dart";
import "package:loure/consts/base.dart";
import "package:loure/consts/base_consts.dart";
import "package:loure/data/event_mem_box.dart";
import "package:loure/main.dart";
import "package:loure/provider/follow_event_provider.dart";
import "package:loure/provider/follow_new_event_provider.dart";
import "package:provider/provider.dart";

import "package:loure/component/event/event_list_component.dart";
import "package:loure/component/placeholder/event_list_placeholder.dart";
import "package:loure/provider/setting_provider.dart";
import "package:loure/util/load_more_event.dart";
import "package:loure/util/platform_util.dart";

class FollowPostsRouter extends StatefulWidget {
  const FollowPostsRouter({super.key});

  @override
  State<StatefulWidget> createState() {
    return _FollowPostsRouter();
  }
}

class _FollowPostsRouter extends KeepAliveCustState<FollowPostsRouter>
    with LoadMoreEvent {
  final ScrollController _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    bindLoadMoreScroll(_controller);
  }

  @override
  Widget doBuild(final BuildContext context) {
    final settingProvider = Provider.of<SettingProvider>(context);
    final followEventProvider = Provider.of<FollowEventProvider>(context);

    final eventBox = followEventProvider.postsBox;
    final events = eventBox.all();
    if (events.isEmpty) {
      return EventListPlaceholder(
        onRefresh: () {
          followEventProvider.refresh();
        },
      );
    }
    indexProvider.setFollowPostsScrollController(_controller);
    preBuild();

    final main = ListView.builder(
      controller: _controller,
      itemBuilder: (final BuildContext context, final int index) {
        final event = events[index];
        return EventListComponent(
          event: event,
          showVideo: settingProvider.videoPreviewInList == OpenStatus.OPEN,
        );
      },
      itemCount: events.length,
    );

    Widget ri = RefreshIndicator(
      onRefresh: () async {
        followEventProvider.refresh();
      },
      child: main,
    );

    if (PlatformUtil.isTableMode()) {
      ri = GestureDetector(
        onVerticalDragUpdate: (final detail) {
          _controller.jumpTo(_controller.offset - detail.delta.dy);
        },
        behavior: HitTestBehavior.translucent,
        child: ri,
      );
    }

    List<Widget> stackList = [ri];
    stackList.add(Positioned(
      top: Base.BASE_PADDING,
      child: Selector<FollowNewEventProvider, int>(
        builder: (final context, final newEventNum, final child) {
          if (newEventNum <= 0) {
            return Container();
          }

          return NewNotesUpdatedComponent(
            num: newEventNum,
            onTap: () {
              followEventProvider.mergeNewEvent();
              _controller.jumpTo(0);
            },
          );
        },
        selector: (final context, final provider) {
          return provider.eventPostMemBox.length();
        },
      ),
    ));
    return Stack(
      alignment: Alignment.center,
      children: stackList,
    );
  }

  @override
  void doQuery() {
    preQuery();
    followEventProvider.doQuery(until: until, forceUserLimit: forceUserLimit);
  }

  @override
  EventMemBox getEventBox() {
    return followEventProvider.postsBox;
  }

  @override
  Future<void> onReady(final BuildContext context) async {}
}
