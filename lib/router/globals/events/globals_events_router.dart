import "package:flutter/material.dart";
import "package:loure/client/relay/relay_pool.dart";
import "package:provider/provider.dart";

import "package:loure/component/event_delete_callback.dart";
import "package:loure/component/keep_alive_cust_state.dart";
import "package:loure/client/event.dart";
import "package:loure/client/event_kind.dart";
import "package:loure/client/filter.dart";
import "package:loure/component/event/event_list_component.dart";
import "package:loure/component/placeholder/event_list_placeholder.dart";
import "package:loure/consts/base_consts.dart";
import "package:loure/data/event_mem_box.dart";
import "package:loure/main.dart";
import "package:loure/provider/setting_provider.dart";
import "package:loure/util/pendingevents_later_function.dart";
import "package:loure/util/platform_util.dart";

class GlobalsEventsRouter extends StatefulWidget {
  const GlobalsEventsRouter({super.key});

  @override
  State<StatefulWidget> createState() {
    return _GlobalsEventsRouter();
  }
}

class _GlobalsEventsRouter extends KeepAliveCustState<GlobalsEventsRouter>
    with PendingEventsLaterFunction {
  ScrollController scrollController = ScrollController();

  ManySubscriptionHandle? subHandle;
  EventMemBox eventBox = EventMemBox(sortAfterAdd: false);

  @override
  Widget doBuild(final BuildContext context) {
    final settingProvider = Provider.of<SettingProvider>(context);
    if (eventBox.isEmpty()) {
      return EventListPlaceholder();
    }

    final list = eventBox.all();

    final main = EventDeleteCallback(
      onDeleteCallback: onDeleteCallback,
      child: ListView.builder(
        controller: scrollController,
        itemBuilder: (final context, final index) {
          final event = list[index];
          return EventListComponent(
            event: event,
            showVideo: settingProvider.videoPreviewInList == OpenStatus.OPEN,
          );
        },
        itemCount: list.length,
      ),
    );

    if (PlatformUtil.isTableMode()) {
      return GestureDetector(
        onVerticalDragUpdate: (final detail) {
          scrollController.jumpTo(scrollController.offset - detail.delta.dy);
        },
        behavior: HitTestBehavior.translucent,
        child: main,
      );
    }

    return main;
  }

  @override
  Future<void> onReady(final BuildContext context) async {
    indexProvider.setEventScrollController(scrollController);
    refresh();
  }

  Future<void> refresh() async {
    this.subHandle = pool.subscribeMany(nostr.relayList.read, [
      Filter(kinds: [EventKind.TEXT_NOTE])
    ], onEvent: (final event) {
      if (eventBox.isEmpty()) {
        laterTimeMS = 200;
      } else {
        laterTimeMS = 1000;
      }

      later(event, (final list) {
        eventBox.addList(list);
        setState(() {});
      }, null);
    });
  }

  @override
  void dispose() {
    super.dispose();

    if (this.subHandle != null) {
      this.subHandle!.close();
    }

    disposeLater();
  }

  onDeleteCallback(final Event event) {
    eventBox.delete(event.id);
    setState(() {});
  }
}
