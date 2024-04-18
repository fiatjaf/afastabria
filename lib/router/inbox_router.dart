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

class InboxRouter extends StatefulWidget {
  const InboxRouter({super.key});

  @override
  State<StatefulWidget> createState() => InboxRouterState();
}

class InboxRouterState extends State<InboxRouter>
    with AutomaticKeepAliveClientMixin<InboxRouter> {
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
    inboxManager.newEvents.addListener(this.onNewEvent.call);
  }

  @override
  void dispose() {
    super.dispose();
    inboxManager.newEvents.removeListener(this.onNewEvent.call);
  }

  @override
  Widget build(final BuildContext context) {
    super.build(context);

    final showVideo =
        Provider.of<SettingProvider>(context).videoPreviewInList ==
            OpenStatus.OPEN;

    indexProvider.setInboxScrollController(scrollController);

    return Stack(alignment: Alignment.center, children: [
      ListenableBuilder(
        listenable: inboxManager,
        builder: (final context, final child) {
          if (inboxManager.events.isEmpty) {
            return const EventListPlaceholder();
          }

          return ListView.builder(
            controller: scrollController,
            itemBuilder: (final context, final int index) {
              return EventListComponent(
                event: inboxManager.events[index],
                showVideo: showVideo,
              );
            },
            itemCount: inboxManager.events.length,
          );
        },
      ),
      Positioned(
        top: Base.BASE_PADDING,
        child: ValueListenableBuilder<int>(
          valueListenable: inboxManager.newEvents,
          builder: (final context, final num_, final child) =>
              NewNotesUpdatedComponent(
            num: num_ - 1,
            onTap: () {
              inboxManager.mergeNewNotes();
              scrollController.jumpTo(0);
            },
          ),
        ),
      ),
    ]);
  }

  void handleNewEvent() {
    if (inboxManager.events.length == 0 ||
        this.scrollController.position.pixels < 0.1) {
      inboxManager.mergeNewNotes();
    }
  }
}
