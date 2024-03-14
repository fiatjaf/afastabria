import 'package:flutter/material.dart';

import 'package:nostrmo/client/event.dart';
import 'package:nostrmo/consts/base.dart';
import 'package:nostrmo/data/event_find_util.dart';
import 'package:nostrmo/util/router_util.dart';
import 'package:nostrmo/util/string_util.dart';
import 'package:nostrmo/util/when_stop_function.dart';
import 'package:nostrmo/component/event/event_list_component.dart';
import 'package:nostrmo/component/editor/search_mention_component.dart';

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
  Widget build(BuildContext context) {
    return SaerchMentionComponent(
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
        itemBuilder: (context, index) {
          var event = events[index];
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

  void handleSearch(String? text) {
    events.clear();
    if (StringUtil.isNotBlank(text)) {
      var list = EventFindUtil.findEvent(text!, limit: searchMemLimit);
      setState(() {
        events = list;
      });
    }
  }
}
