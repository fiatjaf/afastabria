import 'package:flutter/material.dart';
import 'package:nostr_dart/nostr_dart.dart';
import 'package:nostrmo/client/event_relation.dart';
import 'package:nostrmo/component/event/event_list_component.dart';
import 'package:nostrmo/router/thread/thread_detail_event.dart';
import 'package:nostrmo/router/thread/thread_detail_item_component.dart';

import '../../client/filter.dart';
import '../../component/cust_state.dart';
import '../../data/event_mem_box.dart';
import '../../main.dart';
import '../../util/peddingevents_lazy_function.dart';
import '../../util/router_util.dart';
import '../../client/event_kind.dart' as kind;

class ThreadDetailRouter extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _ThreadDetailRouter();
  }
}

class _ThreadDetailRouter extends CustState<ThreadDetailRouter>
    with PenddingEventsLazyFunction {
  EventMemBox box = EventMemBox();

  Event? sourceEvent;

  @override
  Widget doBuild(BuildContext context) {
    if (sourceEvent == null) {
      var obj = RouterUtil.routerArgs(context);
      if (obj != null && obj is Event) {
        sourceEvent = obj;
      }
      if (sourceEvent == null) {
        RouterUtil.back(context);
        return Container();
      }
    }

    if (rootEvent == null || rootSubList == null || rootSubList!.isEmpty) {
      return Scaffold(
        body: Center(
          child: Text("Thread Detail"),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () {
            RouterUtil.back(context);
          },
          child: Icon(Icons.arrow_back_ios),
        ),
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return <Widget>[
            SliverToBoxAdapter(
              child: EventListComponent(event: rootEvent!),
            ),
          ];
        },
        body: ListView.builder(
          itemBuilder: (context, index) {
            var item = rootSubList![index];
            return ThreadDetailItemComponent(item: item);
          },
          itemCount: rootSubList!.length,
        ),
      ),
    );
  }

  @override
  Future<void> onReady(BuildContext context) async {
    if (sourceEvent != null) {
      var eventRelation = EventRelation.fromEvent(sourceEvent!);
      var rootId = eventRelation.rootId;
      if (rootId == null) {
        // source event is root event
        rootId = sourceEvent!.id;
        rootEvent = sourceEvent!;
      } else {
        // source event isn't root event，query root event
        var filter = Filter(ids: [rootId]);
        nostr!.pool.query([filter.toJson()], onRootEvent);
      }

      // query sub events
      var filter = Filter(e: [rootId], kinds: [kind.EventKind.TEXT_NOTE]);
      nostr!.pool.query([filter.toJson()], onEvent);
    }
  }

  Event? rootEvent;

  List<ThreadDetailEvent>? rootSubList;

  void onRootEvent(Event event) {
    rootEvent = event;
  }

  void onEvent(Event event) {
    lazy(event, (list) {
      box.addList(list);
      listToTree();
    }, null);
  }

  void listToTree() {
    // event in box had been sorted. The last one is the oldest.
    var all = box.all();
    var length = all.length;
    List<ThreadDetailEvent> _rootSubList = [];
    // key - id, value - item
    Map<String, ThreadDetailEvent> itemMap = {};
    for (var i = length - 1; i > -1; i--) {
      var event = all[i];
      var item = ThreadDetailEvent(event: event);
      itemMap[event.id] = item;
    }

    for (var i = length - 1; i > -1; i--) {
      var event = all[i];
      var relation = EventRelation.fromEvent(event);
      var item = itemMap[event.id]!;

      if (relation.replyId == null) {
        _rootSubList.add(item);
      } else {
        var replyItem = itemMap[relation.replyId];
        if (replyItem == null) {
          _rootSubList.add(item);
        } else {
          replyItem.subItems.add(item);
        }
      }
    }

    rootSubList = _rootSubList;
    setState(() {});
  }
}