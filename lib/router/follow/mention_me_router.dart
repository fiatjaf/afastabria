import 'package:flutter/material.dart';
import 'package:loure/component/keep_alive_cust_state.dart';
import 'package:loure/data/event_mem_box.dart';
import 'package:loure/main.dart';
import 'package:loure/provider/mention_me_new_provider.dart';
import 'package:loure/provider/mention_me_provider.dart';
import 'package:loure/util/load_more_event.dart';
import 'package:loure/util/string_util.dart';
import 'package:provider/provider.dart';

import 'package:loure/client/event_kind.dart' as kind;
import 'package:loure/component/badge_award_component.dart';
import 'package:loure/component/event/event_list_component.dart';
import 'package:loure/component/event/zap_event_list_component.dart';
import 'package:loure/component/new_notes_updated_component.dart';
import 'package:loure/component/placeholder/event_list_placeholder.dart';
import 'package:loure/consts/base.dart';
import 'package:loure/consts/base_consts.dart';
import 'package:loure/provider/setting_provider.dart';
import 'package:loure/util/platform_util.dart';

class MentionMeRouter extends StatefulWidget {
  const MentionMeRouter({super.key});

  @override
  State<StatefulWidget> createState() {
    return _MentionMeRouter();
  }
}

class _MentionMeRouter extends KeepAliveCustState<MentionMeRouter>
    with LoadMoreEvent {
  final ScrollController _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    bindLoadMoreScroll(_controller);
  }

  @override
  Widget doBuild(BuildContext context) {
    var settingProvider = Provider.of<SettingProvider>(context);
    var mentionMeProvider = Provider.of<MentionMeProvider>(context);
    var eventBox = mentionMeProvider.eventBox;
    var events = eventBox.all();
    if (events.isEmpty) {
      return EventListPlaceholder(
        onRefresh: () {
          mentionMeProvider.refresh();
        },
      );
    }
    indexProvider.setMentionedScrollController(_controller);
    preBuild();

    var main = ListView.builder(
      controller: _controller,
      itemBuilder: (BuildContext context, int index) {
        var event = events[index];
        if (event.kind == kind.EventKind.ZAP &&
            StringUtil.isBlank(event.content)) {
          return ZapEventListComponent(event: event);
        } else if (event.kind == kind.EventKind.BADGE_AWARD) {
          return BadgeAwardComponent(event: event);
        } else {
          return EventListComponent(
            event: event,
            showVideo: settingProvider.videoPreviewInList == OpenStatus.OPEN,
          );
        }
      },
      itemCount: events.length,
    );

    Widget ri = RefreshIndicator(
      onRefresh: () async {
        mentionMeProvider.refresh();
      },
      child: main,
    );

    if (PlatformUtil.isTableMode()) {
      ri = GestureDetector(
        onVerticalDragUpdate: (detail) {
          _controller.jumpTo(_controller.offset - detail.delta.dy);
        },
        behavior: HitTestBehavior.translucent,
        child: ri,
      );
    }

    List<Widget> stackList = [ri];
    stackList.add(Positioned(
      top: Base.BASE_PADDING,
      child: Selector<MentionMeNewProvider, int>(
        builder: (context, newEventNum, child) {
          if (newEventNum <= 0) {
            return Container();
          }

          return NewNotesUpdatedComponent(
            num: newEventNum,
            onTap: () {
              mentionMeProvider.mergeNewEvent();
              _controller.jumpTo(0);
            },
          );
        },
        selector: (context, provider) {
          return provider.eventMemBox.length();
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
    mentionMeProvider.doQuery(until: until);
  }

  @override
  EventMemBox getEventBox() {
    return mentionMeProvider.eventBox;
  }

  @override
  Future<void> onReady(BuildContext context) async {}
}
