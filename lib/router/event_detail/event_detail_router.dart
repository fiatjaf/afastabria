import 'package:flutter/material.dart';
import 'package:loure/main.dart';
import 'package:provider/provider.dart';
import 'package:widget_size/widget_size.dart';

import 'package:loure/client/event.dart';
import 'package:loure/client/filter.dart';
import 'package:loure/client/event_kind.dart' as kind;
import 'package:loure/component/event/event_list_component.dart';
import 'package:loure/component/event/event_load_list_component.dart';
import 'package:loure/component/event/reaction_event_list_component.dart';
import 'package:loure/component/event/zap_event_list_component.dart';
import 'package:loure/data/event_reactions.dart';
import 'package:loure/provider/event_reactions_provider.dart';
import 'package:loure/util/platform_util.dart';
import 'package:loure/util/router_util.dart';
import 'package:loure/router/thread/thread_detail_router.dart';

class EventDetailRouter extends StatefulWidget {
  const EventDetailRouter({super.key});

  @override
  State<StatefulWidget> createState() {
    return _EventDetailRouter();
  }
}

class _EventDetailRouter extends State<EventDetailRouter> {
  bool showTitle = false;
  final ScrollController _controller = ScrollController();
  double rootEventHeight = 120;
  Future<Event?>? eventFuture;

  @override
  void initState() {
    super.initState();

    _controller.addListener(() {
      if (_controller.offset > rootEventHeight * 0.8 && !showTitle) {
        setState(() {
          showTitle = true;
        });
      } else if (_controller.offset < rootEventHeight * 0.8 && showTitle) {
        setState(() {
          showTitle = false;
        });
      }
    });

    var arg = RouterUtil.routerArgs(context);
    if (arg != null) {
      if (arg is Event) {
        this.eventFuture = Future.value(arg);
      } else if (arg is String) {
        var eventId = arg;
        var evt = nostr.eventIndex[eventId];
        if (evt != null) {
          eventFuture = Future.value(evt);
          return;
        } else {
          eventFuture =
              nostr.pool.querySingle(nostr.ID_RELAYS, Filter(ids: [eventId]));
          return;
        }
      }
    }

    RouterUtil.back(context);
    return;
  }

  @override
  Widget build(BuildContext context) {
    var themeData = Theme.of(context);

    Widget? appBarTitle;
    if (showTitle) {
      appBarTitle = FutureBuilder(
        future: this.eventFuture,
        initialData: null,
        builder: (context, snapshot) {
          if (snapshot.data != null) {
            return ThreadDetailRouter.detailAppBarTitle(
                snapshot.data!, themeData);
          } else {
            return Container();
          }
        },
      );
    }

    final mainEventWidget = FutureBuilder(
      future: eventFuture,
      initialData: null,
      builder: (context, snapshot) {
        if (snapshot.data == null) {
          return const EventLoadListComponent();
        } else {
          return EventListComponent(
            event: snapshot.data!,
            showVideo: true,
            showDetailBtn: false,
          );
        }
      },
    );

    final mainWidget = Selector<EventReactionsProvider, EventReactions?>(
      builder: (context, eventReactions, child) {
        if (eventReactions == null) {
          return mainEventWidget;
        }

        List<Event> allEvent = [];
        allEvent.addAll(eventReactions.replies);
        allEvent.addAll(eventReactions.reposts);
        allEvent.addAll(eventReactions.likes);
        allEvent.addAll(eventReactions.zaps);
        allEvent.sort((event1, event2) {
          return event2.createdAt - event1.createdAt;
        });

        Widget main = ListView.builder(
          controller: _controller,
          itemBuilder: (context, index) {
            if (index == 0) {
              return WidgetSize(
                child: mainEventWidget,
                onChange: (size) {
                  rootEventHeight = size.height;
                },
              );
            }

            var event = allEvent[index - 1];
            if (event.kind == kind.EventKind.ZAP) {
              return ZapEventListComponent(event: event);
            } else if (event.kind == kind.EventKind.TEXT_NOTE) {
              return ReactionEventListComponent(event: event, text: "replied");
            } else if (event.kind == kind.EventKind.REPOST ||
                event.kind == kind.EventKind.GENERIC_REPOST) {
              return ReactionEventListComponent(event: event, text: "boosted");
            } else if (event.kind == kind.EventKind.REACTION) {
              return ReactionEventListComponent(event: event, text: "liked");
            }

            return Container();
          },
          itemCount: allEvent.length + 1,
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

        return main;
      },
      selector: (context, provider) {
        return provider.get(eventId);
      },
      shouldRebuild: (previous, next) {
        if ((previous == null && next != null) ||
            (previous != null &&
                next != null &&
                (previous.replies.length != next.replies.length ||
                    previous.repostNum != next.repostNum ||
                    previous.likeNum != next.likeNum ||
                    previous.zapNum != next.zapNum))) {
          return true;
        }

        return false;
      },
    );

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
        title: appBarTitle,
      ),
      body: mainWidget,
    );
  }
}
