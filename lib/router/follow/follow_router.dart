import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "package:easy_debounce/easy_debounce.dart";

import "package:loure/main.dart";
import "package:loure/component/event/event_list_component.dart";
import "package:loure/component/new_notes_updated_component.dart";
import "package:loure/component/placeholder/event_list_placeholder.dart";
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
  static const debounceDuration = Duration(seconds: 3);

  final ScrollController scrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    scrollController.addListener(handleScroll);
    followingManager.newEvents.addListener(newEventArrived);
  }

  @override
  void dispose() {
    super.dispose();

    scrollController.removeListener(handleScroll);
    followingManager.newEvents.removeListener(newEventArrived);
  }

  @override
  Widget build(final BuildContext context) {
    super.build(context);

    final showVideo =
        Provider.of<SettingProvider>(context).videoPreviewInList ==
            OpenStatus.OPEN;

    indexProvider.setFollowScrollController(scrollController);

    return Stack(alignment: Alignment.center, children: [
      ListenableBuilder(
        listenable: followingManager,
        builder: (final context, final child) => ListView.builder(
          controller: scrollController,
          itemBuilder: (final context, final int index) {
            if (followingManager.events.isEmpty) {
              return EventListPlaceholder();
            }

            return EventListComponent(
              event: followingManager.events[index],
              showVideo: showVideo,
            );
          },
          itemCount: followingManager.events.length,
        ),
      ),
      Positioned(
        top: Base.BASE_PADDING,
        child: ValueListenableBuilder<int>(
          valueListenable: followingManager.newEvents,
          builder: (final context, final num_, final child) =>
              NewNotesUpdatedComponent(
            num: num_,
            onTap: () {
              followingManager.mergeNewNotes();
              scrollController.jumpTo(0);
            },
          ),
        ),
      ),
    ]);
  }

  void handleScroll() {
    print("scrolled: ${scrollController.position.pixels}");
  }

  void newEventArrived() {
    EasyDebounce.debounce(
        "neweventarrived", debounceDuration, this.handleNewEvent);
  }

  void handleNewEvent() {
    if (this.scrollController.position.pixels < 0.1) {
      followingManager.mergeNewNotes();
    }
  }
}
