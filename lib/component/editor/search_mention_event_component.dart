import "package:flutter/material.dart";

import "package:loure/client/event.dart";
import "package:loure/consts/base.dart";
import "package:loure/data/event_find_util.dart";
import "package:loure/util/router_util.dart";
import "package:loure/util/string_util.dart";
import "package:loure/util/when_stop_function.dart";
import "package:loure/component/event/event_list_component.dart";
import "package:loure/component/editor/search_mention_component.dart";

class SearchMentionEventComponent extends StatefulWidget {
  const SearchMentionEventComponent({super.key});

  @override
  State<StatefulWidget> createState() {
    return _SearchMentionEventComponent();
  }
}

class _SearchMentionEventComponent extends State<SearchMentionEventComponent>
    with WhenStopFunction {
  @override
  Widget build(final BuildContext context) {
    return SearchMentionComponent(
      resultBuildFunc: resultBuild,
      handleSearchFunc: handleSearch,
    );
  }

  Widget resultBuild() {
    return Container(
      padding: const EdgeInsets.only(
        top: Base.BASE_PADDING_HALF,
        bottom: Base.BASE_PADDING_HALF,
      ),
      child: ListView.builder(
        itemBuilder: (final context, final index) {
          final event = events[index];
          return GestureDetector(
            onTap: () {
              RouterUtil.back(context, event.id);
            },
            child: EventListComponent(
              event: event,
              jumpable: false,
            ),
          );
        },
        itemCount: events.length,
      ),
    );
  }

  static const int searchMemLimit = 100;

  List<Event> events = [];

  void handleSearch(final String? text) {
    events.clear();
    if (StringUtil.isNotBlank(text)) {
      final list = EventFindUtil.findEvent(text!, limit: searchMemLimit);
      setState(() {
        events = list;
      });
    }
  }
}
