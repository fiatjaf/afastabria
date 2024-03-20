import "package:flutter/material.dart";
import "package:provider/provider.dart";

import "package:loure/main.dart";
import "package:loure/component/event/event_list_component.dart";
import "package:loure/component/new_notes_updated_component.dart";
// import "package:loure/component/placeholder/event_list_placeholder.dart";
import "package:loure/consts/base.dart";
import "package:loure/consts/base_consts.dart";
import "package:loure/provider/setting_provider.dart";

class FollowRouter extends StatefulWidget {
  const FollowRouter({super.key});

  @override
  State<StatefulWidget> createState() => FollowRouterState();
}

class FollowRouterState extends State<FollowRouter>
    with AutomaticKeepAliveClientMixin<FollowRouter> {
  final ScrollController scrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    scrollController.addListener(handleScroll);
  }

  @override
  Widget build(final BuildContext context) {
    super.build(context);

    final showVideo =
        Provider.of<SettingProvider>(context).videoPreviewInList ==
            OpenStatus.OPEN;

    // if (events.isEmpty) {
    //   return EventListPlaceholder(
    //     onRefresh: () {
    //       followEventProvider.refresh();
    //     },
    //   );
    // }

    indexProvider.setFollowScrollController(scrollController);

    return Stack(alignment: Alignment.center, children: [
      ListView.builder(
        controller: scrollController,
        itemBuilder: (final BuildContext context, final int index) {
          return EventListComponent(
            event: followingManager.events[index],
            showVideo: showVideo,
          );
        },
        itemCount: followingManager.events.length,
      ),
      Positioned(
        top: Base.BASE_PADDING,
        child: StreamBuilder<int>(
          stream: followingManager.newEventsCountStream,
          initialData: 0,
          builder: (final context, final snapshot) {
            return NewNotesUpdatedComponent(
              num: snapshot.data!,
              onTap: () {
                scrollController.jumpTo(0);
              },
            );
          },
        ),
      ),
    ]);
  }

  void handleScroll() {
    print("scrolled: ${scrollController.position.pixels}");
  }
}
