import 'package:flutter/material.dart';
import 'package:loure/component/event_delete_callback.dart';
import 'package:loure/router/tag/topic_map.dart';
import 'package:provider/provider.dart';

import 'package:loure/client/event.dart';
import 'package:loure/client/filter.dart';
import 'package:loure/component/cust_state.dart';
import 'package:loure/component/event/event_list_component.dart';
import 'package:loure/component/tag_info_component.dart';
import 'package:loure/consts/base_consts.dart';
import 'package:loure/data/event_mem_box.dart';
import 'package:loure/main.dart';
import 'package:loure/provider/setting_provider.dart';
import 'package:loure/util/pendingevents_later_function.dart';
import 'package:loure/util/platform_util.dart';
import 'package:loure/util/router_util.dart';
import 'package:loure/client/event_kind.dart';
import 'package:loure/util/string_util.dart';

class TagDetailRouter extends StatefulWidget {
  const TagDetailRouter({super.key});

  @override
  State<StatefulWidget> createState() {
    return _TagDetailRouter();
  }
}

class _TagDetailRouter extends CustState<TagDetailRouter>
    with PendingEventsLaterFunction {
  EventMemBox box = EventMemBox();

  final ScrollController _controller = ScrollController();

  bool showTitle = false;

  double tagHeight = 80;

  String? tag;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      if (_controller.offset > tagHeight * 0.8 && !showTitle) {
        setState(() {
          showTitle = true;
        });
      } else if (_controller.offset < tagHeight * 0.8 && showTitle) {
        setState(() {
          showTitle = false;
        });
      }
    });
  }

  @override
  Widget doBuild(BuildContext context) {
    var settingProvider = Provider.of<SettingProvider>(context);
    if (StringUtil.isBlank(tag)) {
      var arg = RouterUtil.routerArgs(context);
      if (arg != null && arg is String) {
        tag = arg;
      }
    } else {
      var arg = RouterUtil.routerArgs(context);
      if (arg != null && arg is String && tag != arg) {
        // arg changed! reset
        tag = arg;

        box = EventMemBox();
        doQuery();
      }
    }
    if (StringUtil.isBlank(tag)) {
      RouterUtil.back(context);
      return Container();
    }

    var themeData = Theme.of(context);
    var bodyLargeFontSize = themeData.textTheme.bodyLarge!.fontSize;

    Widget? appBarTitle;
    if (showTitle) {
      appBarTitle = Text(
        tag!,
        style: TextStyle(
          fontSize: bodyLargeFontSize,
          overflow: TextOverflow.ellipsis,
        ),
      );
    }

    Widget main = EventDeleteCallback(
      onDeleteCallback: onDeleteCallback,
      child: ListView.builder(
        controller: _controller,
        itemBuilder: (context, index) {
          if (index == 0) {
            return TagInfoComponent(
              tag: tag!,
              height: tagHeight,
            );
          }

          var event = box.get(index - 1);
          if (event == null) {
            return null;
          }

          return EventListComponent(
            event: event,
            showVideo: settingProvider.videoPreviewInList == OpenStatus.OPEN,
          );
        },
        itemCount: box.length() + 1,
      ),
    );

    if (PlatformUtil.isTableMode()) {
      main = GestureDetector(
        onVerticalDragUpdate: (detail) {
          _controller.jumpTo(_controller.offset - detail.delta.dy);
        },
        behavior: HitTestBehavior.translucent,
        child: main,
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () {
            RouterUtil.back(context);
          },
          child: Icon(
            Icons.arrow_back_ios,
            color: themeData.appBarTheme.titleTextStyle!.color,
          ),
        ),
        actions: const [],
        title: appBarTitle,
      ),
      body: main,
    );
  }

  @override
  Future<void> onReady(BuildContext context) async {
    doQuery();
  }

  void doQuery() {
    // tag query
    // https://github.com/nostr-protocol/nips/blob/master/12.md
    var filter = Filter(kinds: EventKind.SUPPORTED_EVENTS, limit: 100);
    var plainTag = tag!.replaceFirst("#", "");
    // this place set #t not #r ???
    var list = TopicMap.getList(plainTag);
    if (list != null) {
      filter.t = list;
    } else {
      // can't find from topicMap, change to query the source, upperCase and lowerCase
      var upperCase = plainTag.toUpperCase();
      var lowerCase = plainTag.toLowerCase();
      list = [upperCase];
      if (upperCase != lowerCase) {
        list.add(lowerCase);
      }
      if (upperCase != plainTag && lowerCase != plainTag) {
        list.add(plainTag);
      }
      filter.t = list;
    }
    nostr.pool.subscribeManyEose(["wss://relay.nostr.band"], [filter],
        onEvent: onEvent);
  }

  void onEvent(Event? event) {
    if (event == null) return;

    later(event, (list) {
      box.addList(list);
      setState(() {});
    }, null);
  }

  @override
  void dispose() {
    super.dispose();
    disposeLater();
  }

  onDeleteCallback(Event event) {
    box.delete(event.id);
    setState(() {});
  }
}
