import "package:flutter/material.dart";
import "package:loure/client/relay/relay_pool.dart";
import "package:widget_size/widget_size.dart";

import "package:loure/client/aid.dart";
import "package:loure/client/event.dart";
import "package:loure/client/event_relation.dart";
import "package:loure/client/filter.dart";
import "package:loure/component/event/event_list_component.dart";
import "package:loure/component/event/event_load_list_component.dart";
import "package:loure/component/event_reply_callback.dart";
import "package:loure/component/simple_name_component.dart";
import "package:loure/consts/base.dart";
import "package:loure/data/event_mem_box.dart";
import "package:loure/main.dart";
import "package:loure/util/pendingevents_later_function.dart";
import "package:loure/util/platform_util.dart";
import "package:loure/util/router_util.dart";
import "package:loure/client/event_kind.dart";
import "package:loure/util/string_util.dart";
import "package:loure/util/when_stop_function.dart";
import "package:loure/router/thread/thread_detail_event.dart";
import "package:loure/router/thread/thread_detail_event_main_component.dart";
import "package:loure/router/thread/thread_detail_item_component.dart";

class ThreadDetailRouter extends StatefulWidget {
  const ThreadDetailRouter(dynamic arg, {super.key})
      : this.sourceEvent = arg != null && arg is Event ? arg : null;

  final Event? sourceEvent;

  @override
  State<StatefulWidget> createState() {
    return ThreadDetailRouterState();
  }

  static Widget detailAppBarTitle(
      final Event event, final ThemeData themeData) {
    final bodyLargeFontSize = themeData.textTheme.bodyLarge!.fontSize;

    List<Widget> appBarTitleList = [];
    final nameComponent = SimpleNameComponent(
      pubkey: event.pubkey,
      textStyle: TextStyle(
        fontSize: bodyLargeFontSize,
        color: themeData.appBarTheme.titleTextStyle!.color,
      ),
    );
    appBarTitleList.add(nameComponent);
    appBarTitleList.add(const Text(" : "));
    appBarTitleList.add(Expanded(
        child: Text(
      event.content.replaceAll("\n", " ").replaceAll("\r", " "),
      style: TextStyle(
        overflow: TextOverflow.ellipsis,
        fontSize: bodyLargeFontSize,
      ),
    )));
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: appBarTitleList,
    );
  }
}

class ThreadDetailRouterState extends State<ThreadDetailRouter>
    with PendingEventsLaterFunction, WhenStopFunction {
  ThreadDetailRouterState();

  EventMemBox box = EventMemBox();
  bool showTitle = false;
  final ScrollController _controller = ScrollController();
  double rootEventHeight = 120;
  Future<Event?>? rootEventFuture;
  AId? aId;
  String? rootId;
  List<ThreadDetailEvent>? rootSubList = [];
  ManySubscriptionHandle? repliesSubHandle;
  GlobalKey sourceEventKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    this._controller.addListener(() {
      if (this._controller.offset > this.rootEventHeight * 0.8 &&
          !this.showTitle) {
        setState(() {
          this.showTitle = true;
        });
      } else if (this._controller.offset < this.rootEventHeight * 0.8 &&
          this.showTitle) {
        setState(() {
          this.showTitle = false;
        });
      }
    });

    this.initFromArgs();
    this.subscribeReplies();
  }

  @override
  void didUpdateWidget(ThreadDetailRouter oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.sourceEvent == null) {
      RouterUtil.back(context);
      return;
    } else if (oldWidget.sourceEvent == widget.sourceEvent) {
      // same stuff, do nothing
      return;
    } else {
      // arg change! reset.
      this.rootId = null;
      this.box = EventMemBox();
      this.rootSubList = [];

      this.initFromArgs();
      this.subscribeReplies();
    }
  }

  void initFromArgs() {
    final eventRelation = EventRelation.fromEvent(widget.sourceEvent!);
    this.rootId = eventRelation.rootId;

    if (eventRelation.aId != null &&
        eventRelation.aId!.kind == EventKind.LONG_FORM) {
      this.aId = eventRelation.aId;
    }

    // TODO: if we have a rootId and also an aId and we can't find the rootEvent with the id, try with the aId
    if (this.rootId != null) {
      this.rootEventFuture = nostr.getByID(this.rootId!);
    } else {
      if (this.aId == null) {
        if (eventRelation.replyId != null) {
          this.rootId = eventRelation.replyId;
          this.rootEventFuture = nostr.getByID(this.rootId!);
        } else {
          // source event is root event
          // TODO: check if source is a replaceable event and check tags here instead of just id
          this.rootId = widget.sourceEvent!.id;
          this.rootEventFuture = Future.value(widget.sourceEvent!);
        }
      } else {
        // aid linked root event
        this.rootEventFuture = nostr.getByAddress(aId!);
      }
    }

    this.rootEventFuture!.then((final Event? rootEvent) {
      // if (rootEvent != null && StringUtil.isNotBlank(eventRelation.dTag)) {
      //   aId = AId(
      //       kind: rootEvent!.kind,
      //       pubkey: rootEvent!.pubkey,
      //       identifier: eventRelation.dTag!);
      // }

      // load replies from cache and avoid blank page
      {
        final eventReactions =
            eventReactionsProvider.get(widget.sourceEvent!.id, avoidPull: true);
        if (eventReactions != null && eventReactions.replies.isNotEmpty) {
          box.addList(eventReactions.replies);
        }
      }
      if (this.rootId != null && this.rootId != widget.sourceEvent!.id) {
        final eventReactions =
            eventReactionsProvider.get(this.rootId!, avoidPull: true);
        if (eventReactions != null && eventReactions.replies.isNotEmpty) {
          box.addList(eventReactions.replies);
        }
      }
      if (rootEvent == null) {
        box.add(widget.sourceEvent!);
      }
      listToTree(refresh: false);

      if (rootEvent != null) {
        // check if the rootEvent isn't rootEvent
        final newRelation = EventRelation.fromEvent(rootEvent);
        String? newRootId;
        if (newRelation.rootId != null) {
          newRootId = newRelation.rootId;
        } else if (newRelation.replyId != null) {
          newRootId = newRelation.replyId;
        }

        if (newRootId != null) {
          this.rootId = newRootId;
          this.subscribeReplies();
          this.setState(() {
            this.rootEventFuture = nostr.getByID(this.rootId!);
          });
        }
      }
    });
  }

  @override
  Widget build(final BuildContext context) {
    final themeData = Theme.of(context);
    // var bodyLargeFontSize = themeData.textTheme.bodyLarge!.fontSize;
    // var titleTextColor = themeData.appBarTheme.titleTextStyle!.color;
    // var cardColor = themeData.cardColor;

    if (this.rootEventFuture == null) return Container();

    Widget? appBarTitle;
    if (showTitle) {
      appBarTitle = FutureBuilder(
          future: this.rootEventFuture,
          initialData: null,
          builder: (final context, final snapshot) {
            final rootEvent = snapshot.data;
            if (rootEvent != null) {
              return ThreadDetailRouter.detailAppBarTitle(rootEvent, themeData);
            } else {
              return Container();
            }
          });
    }

    final Widget rootEventWidget = FutureBuilder(
      future: this.rootEventFuture,
      initialData: null,
      builder: (final context, final snapshot) {
        final rootEvent = snapshot.data;
        if (rootEvent == null) {
          return const EventLoadListComponent();
        }

        return EventListComponent(
          event: rootEvent,
          jumpable: false,
          showVideo: true,
          imageListMode: false,
          showLongContent: true,
        );
      },
    );

    List<Widget> mainList = [];

    mainList.add(WidgetSize(
      child: rootEventWidget,
      onChange: (final size) {
        rootEventHeight = size.height;
      },
    ));

    for (final item in this.rootSubList!) {
      // if (item.event.kind == kind.EventKind.ZAP &&
      //     StringUtil.isBlank(item.event.content)) {
      //   continue;
      // }

      final totalLevelNum = item.totalLevelNum;
      final needWidth = (totalLevelNum - 1) *
              (Base.BASE_PADDING +
                  ThreadDetailItemMainComponent.BORDER_LEFT_WIDTH) +
          ThreadDetailItemMainComponent.EVENT_MAIN_MIN_WIDTH;
      if (needWidth > mediaDataCache.size.width) {
        mainList.add(SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: needWidth,
            child: ThreadDetailItemComponent(
              item: item,
              totalMaxWidth: needWidth,
              sourceEventId: widget.sourceEvent!.id,
              sourceEventKey: sourceEventKey,
            ),
          ),
        ));
      } else {
        mainList.add(ThreadDetailItemComponent(
          item: item,
          totalMaxWidth: needWidth,
          sourceEventId: widget.sourceEvent!.id,
          sourceEventKey: sourceEventKey,
        ));
      }
    }

    Widget main = ListView(
      controller: _controller,
      children: mainList,
    );

    if (PlatformUtil.isTableMode()) {
      main = GestureDetector(
        onVerticalDragUpdate: (final detail) {
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
        // actions: [
        //   IconButton(
        //     onPressed: () {},
        //     icon: Icon(Icons.more_horiz),
        //   ),
        // ],
        title: appBarTitle,
      ),
      body: EventReplyCallback(
        onReplyCallback: onReplyCallback,
        child: main,
      ),
    );
  }

  void subscribeReplies() {
    if (this.repliesSubHandle != null) this.repliesSubHandle!.close();
    if (this.rootId == null && this.aId == null) return;

    List<int> replyKinds = [...EventKind.SUPPORTED_EVENTS];
    replyKinds.remove(EventKind.REPOST);

    // query sub events
    final filter = this.aId == null
        ? Filter(
            e: [this.rootId!],
            kinds: replyKinds,
          )
        : Filter(
            a: [this.aId!.toTag()],
            kinds: replyKinds,
          );

    this.repliesSubHandle =
        pool.subscribeMany(nostr.relayList.read, [filter], onEvent: onEvent);
  }

  void onEvent(final Event event) {
    if (event.kind == EventKind.ZAP && StringUtil.isBlank(event.content)) {
      return;
    }

    later(event, (final list) {
      box.addList(list);
      listToTree();
      eventReactionsProvider.onEvents(list);
    }, null);
  }

  void listToTree({final bool refresh = true}) {
    // event in box had been sorted. The last one is the oldest.
    final all = box.all();
    final length = all.length;
    List<ThreadDetailEvent> rootSubList = [];
    // key - id, value - item
    Map<String, ThreadDetailEvent> itemMap = {};
    for (var i = length - 1; i > -1; i--) {
      final event = all[i];
      final item = ThreadDetailEvent(event: event);
      itemMap[event.id] = item;
    }

    for (var i = length - 1; i > -1; i--) {
      final event = all[i];
      final relation = EventRelation.fromEvent(event);
      final item = itemMap[event.id]!;

      if (relation.replyId == null) {
        rootSubList.add(item);
      } else {
        final replyItem = itemMap[relation.replyId];
        if (replyItem == null) {
          rootSubList.add(item);
        } else {
          replyItem.subItems.add(item);
        }
      }
    }

    this.rootSubList = rootSubList;
    for (final rootSub in this.rootSubList!) {
      rootSub.handleTotalLevelNum(0);
    }

    if (refresh) {
      // WidgetsBinding.instance.addPostFrameCallback((_) {
      //   Scrollable.ensureVisible(sourceEventKey.currentContext!);
      // });
      whenStop(() {
        if (sourceEventKey.currentContext != null) {
          Scrollable.ensureVisible(sourceEventKey.currentContext!);
        }
      });

      setState(() {});
    }
  }

  @override
  void dispose() {
    super.dispose();
    if (this.repliesSubHandle != null) this.repliesSubHandle!.close();
    disposeLater();
  }

  onReplyCallback(final Event event) {
    onEvent(event);
  }
}
