import "package:flutter/material.dart";
import "package:loure/util/debounce.dart";
import "package:provider/provider.dart";

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
  final ScrollController scrollController = ScrollController();
  late final Debounce onNewEvent;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    this.onNewEvent = Debounce(const Duration(seconds: 2), this.handleNewEvent);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    followingManager.newEvents.addListener(this.onNewEvent.call);
  }

  @override
  void dispose() {
    super.dispose();
    followingManager.newEvents.removeListener(this.onNewEvent.call);
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
        builder: (final context, final child) {
          if (followingManager.events.length == 0) {
            return const EventListPlaceholder();
          }

          return ListView.builder(
            controller: scrollController,
            itemBuilder: (final context, final int index) {
              return EventListComponent(
                event: followingManager.events[index],
                showVideo: showVideo,
              );
            },
            itemCount: followingManager.events.length,
          );
        },
      ),
      Positioned(
        top: Base.BASE_PADDING,
        child: ValueListenableBuilder<int>(
          valueListenable: followingManager.newEvents,
          builder: (final context, final num_, final child) =>
              NewNotesUpdatedComponent(
            num: num_ - 1,
            onTap: () {
              followingManager.mergeNewNotes();
              if (this.scrollController.hasClients) {
                this.scrollController.jumpTo(0);
              }
            },
          ),
        ),
      ),
    ]);
  }

  void handleNewEvent() {
    if (followingManager.events.length == 0 ||
        (this.scrollController.hasClients &&
            this.scrollController.position.pixels < 0.1)) {
      followingManager.mergeNewNotes();
    }
  }
}
