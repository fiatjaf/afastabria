import 'package:flutter/material.dart';
import 'package:nostrmo/client/relay/relay_pool.dart';
import 'package:provider/provider.dart';

import 'package:nostrmo/component/event_delete_callback.dart';
import 'package:nostrmo/component/keep_alive_cust_state.dart';
import 'package:nostrmo/client/event.dart';
import 'package:nostrmo/client/event_kind.dart';
import 'package:nostrmo/client/filter.dart';
import 'package:nostrmo/component/event/event_list_component.dart';
import 'package:nostrmo/component/placeholder/event_list_placeholder.dart';
import 'package:nostrmo/consts/base_consts.dart';
import 'package:nostrmo/data/event_mem_box.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/provider/setting_provider.dart';
import 'package:nostrmo/util/peddingevents_later_function.dart';
import 'package:nostrmo/util/platform_util.dart';

class GlobalsEventsRouter extends StatefulWidget {
  const GlobalsEventsRouter({super.key});

  @override
  State<StatefulWidget> createState() {
    return _GlobalsEventsRouter();
  }
}

class _GlobalsEventsRouter extends KeepAliveCustState<GlobalsEventsRouter>
    with PenddingEventsLaterFunction {
  ScrollController scrollController = ScrollController();

  ManySubscriptionHandler? subHandle;
  EventMemBox eventBox = EventMemBox(sortAfterAdd: false);

  @override
  Widget doBuild(BuildContext context) {
    var settingProvider = Provider.of<SettingProvider>(context);
    if (eventBox.isEmpty()) {
      return EventListPlaceholder();
    }

    var list = eventBox.all();

    var main = EventDeleteCallback(
      onDeleteCallback: onDeleteCallback,
      child: ListView.builder(
        controller: scrollController,
        itemBuilder: (context, index) {
          var event = list[index];
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
        onVerticalDragUpdate: (detail) {
          scrollController.jumpTo(scrollController.offset - detail.delta.dy);
        },
        behavior: HitTestBehavior.translucent,
        child: main,
      );
    }

    return main;
  }

  @override
  Future<void> onReady(BuildContext context) async {
    indexProvider.setEventScrollController(scrollController);
    refresh();
  }

  Future<void> refresh() async {
    this.subHandle = nostr.pool.subscribeMany(nostr.relayList.read, [
      Filter(kinds: [EventKind.TEXT_NOTE])
    ], onEvent: (event) {
      if (eventBox.isEmpty()) {
        laterTimeMS = 200;
      } else {
        laterTimeMS = 1000;
      }

      later(event, (list) {
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

  onDeleteCallback(Event event) {
    eventBox.delete(event.id);
    setState(() {});
  }
}
