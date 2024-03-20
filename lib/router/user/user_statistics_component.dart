import "package:bot_toast/bot_toast.dart";
import "package:flutter/material.dart";
import "package:loure/client/relay/relay_pool.dart";
import "package:loure/provider/contact_list_provider.dart";
import "package:provider/provider.dart";

import "package:loure/client/event.dart";
import "package:loure/client/event_kind.dart" as kind;
import "package:loure/client/nip02/contact_list.dart";
import "package:loure/client/filter.dart";
import "package:loure/client/zap/zap_num_util.dart";
import "package:loure/component/cust_state.dart";
import "package:loure/consts/base.dart";
import "package:loure/consts/router_path.dart";
import "package:loure/data/event_mem_box.dart";
import "package:loure/main.dart";
import "package:loure/util/number_format_util.dart";
import "package:loure/util/router_util.dart";

// ignore: must_be_immutable
class UserStatisticsComponent extends StatefulWidget {
  UserStatisticsComponent({required this.pubkey, super.key});
  String pubkey;

  @override
  State<StatefulWidget> createState() {
    return _UserStatisticsComponent();
  }
}

class _UserStatisticsComponent extends CustState<UserStatisticsComponent> {
  Event? contactListEvent;
  ContactList? contactList;
  Event? relaysEvent;
  List<dynamic>? relaysTags;
  EventMemBox? zapEventBox;
  Map<String, Event>? followedMap;

  int length = 0;
  int relaysNum = 0;
  int followedTagsLength = 0;
  int followedCommunitiesLength = 0;
  int? zapNum;
  int? followedNum;

  bool isLocal = false;
  String? pubkey;

  @override
  Widget doBuild(final BuildContext context) {
    if (pubkey != null && pubkey != widget.pubkey) {
      // arg changed! reset
      this.contactListEvent = null;
      this.contactList = null;
      this.relaysEvent = null;
      this.relaysTags = null;
      this.zapEventBox = null;
      this.followedMap = null;

      this.length = 0;
      this.relaysNum = 0;
      this.followedTagsLength = 0;
      this.followedCommunitiesLength = 0;
      this.zapNum = null;
      this.followedNum = null;
      doQuery();
    }
    pubkey = widget.pubkey;
    isLocal = widget.pubkey == nostr.publicKey;

    List<Widget> list = [];

    if (isLocal) {
      list.add(Selector<ContactListProvider, int>(
          builder: (final context, final num_, final child) {
        return UserStatisticsItemComponent(
          num: num_,
          name: "Following",
          onTap: onFollowingTap,
          onLongPressStart: onLongPressStart,
        );
      }, selector: (final context, final provider) {
        return provider.contactList!.contacts.length;
      }));
    } else {
      if (contactList != null) {
        length = contactList!.contacts.length;
      }
      list.add(UserStatisticsItemComponent(
          num: length, name: "Following", onTap: onFollowingTap));
    }

    if (isLocal) {
      list.add(Selector<RelayPool, int>(
          builder: (final context, final num_, final child) {
        return UserStatisticsItemComponent(
            num: num_, name: "Relays", onTap: onRelaysTap);
      }, selector: (final context, final provider) {
        return provider.relayStatusMap.length;
      }));
    } else {
      if (relaysTags != null) {
        relaysNum = relaysTags!.length;
      }
      list.add(UserStatisticsItemComponent(
          num: relaysNum, name: "Relays", onTap: onRelaysTap));
    }

    list.add(UserStatisticsItemComponent(
      num: followedNum,
      name: "Followed",
      onTap: onFollowedTap,
      formatNum: true,
    ));

    list.add(UserStatisticsItemComponent(
      num: zapNum,
      name: "Zap",
      onTap: onZapTap,
      formatNum: true,
    ));

    return Container(
      // color: Colors.red,
      height: 18,
      margin: const EdgeInsets.only(bottom: Base.BASE_PADDING),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: list,
      ),
    );
  }

  EventMemBox? localContactBox;

  void onLongPressStart(final LongPressStartDetails d) {
    localContactBox = EventMemBox(sortAfterAdd: false);
    pool
        .querySingle(
            nostr.CONTACT_RELAYS,
            Filter(
                authors: [widget.pubkey], kinds: [kind.EventKind.CONTACT_LIST]))
        .then((final event) {
      if (event != null) {
        localContactBox!.add(event);
      }
    });
    BotToast.showText(text: "Begin to load contact history");
  }

  @override
  Future<void> onReady(final BuildContext context) async {
    if (!isLocal) {
      doQuery();
    }
  }

  void doQuery() {
    // {
    //   queryId = StringUtil.rndNameStr(16);
    //   var filter = Filter(
    //       authors: [widget.pubkey],
    //       limit: 1,
    //       kinds: [kind.EventKind.CONTACT_LIST]);
    //   nostr.query([filter.toJson()], (event) {
    //     if (((contactListEvent != null &&
    //                 event.createdAt > contactListEvent!.createdAt) ||
    //             contactListEvent == null) &&
    //         !_disposed) {
    //       setState(() {
    //         contactListEvent = event;
    //         contactList = ContactList.fromJson(event.tags);
    //       });
    //     }
    //   }, id: queryId);
    // }

    // {
    //   queryId2 = StringUtil.rndNameStr(16);
    //   var filter = Filter(
    //       authors: [widget.pubkey],
    //       limit: 1,
    //       kinds: [kind.EventKind.RELAY_LIST_METADATA]);
    //   nostr.query(filter, (event) {
    //     if (((relaysEvent != null &&
    //                 event.createdAt > relaysEvent!.createdAt) ||
    //             relaysEvent == null) &&
    //         !_disposed) {
    //       setState(() {
    //         relaysEvent = event;
    //         relaysTags = event.tags;
    //       });
    //     }
    //   }, id: queryId2);
    // }
  }

  onFollowingTap() {
    if (contactList != null) {
      RouterUtil.router(context, RouterPath.USER_CONTACT_LIST, contactList);
    } else if (isLocal) {
      final cl = contactListProvider.contactList;
      if (cl != null) {
        RouterUtil.router(context, RouterPath.USER_CONTACT_LIST, cl);
      }
    }
  }

  onFollowedTagsTap() {
    if (contactList != null) {
      RouterUtil.router(context, RouterPath.FOLLOWED_TAGS_LIST, contactList);
    } else if (isLocal) {
      final cl = contactListProvider.contactList;
      if (cl != null) {
        RouterUtil.router(context, RouterPath.FOLLOWED_TAGS_LIST, cl);
      }
    }
  }

  String followedSubscribeId = "";

  onFollowedTap() {
    // if (followedMap == null) {
    //   // load data
    //   followedMap = {};
    //   // pull zap event
    //   Map<String, dynamic> filter = {};
    //   filter["kinds"] = [kind.EventKind.CONTACT_LIST];
    //   filter["#p"] = [widget.pubkey];
    //   followedSubscribeId = StringUtil.rndNameStr(12);
    //   nostr.query([filter], (e) {
    //     var oldEvent = followedMap![e.pubKey];
    //     if (oldEvent == null || e.createdAt > oldEvent.createdAt) {
    //       followedMap![e.pubKey] = e;

    //       setState(() {
    //         followedNum = followedMap!.length;
    //       });
    //     }
    //   }, id: followedSubscribeId);

    //   followedNum = 0;
    // } else {
    //   // jump to see
    //   var pubkeys = followedMap!.keys.toList();
    //   RouterUtil.router(context, RouterPath.FOLLOWED, pubkeys);
    // }
  }

  onRelaysTap() {
    if (relaysTags != null && relaysTags!.isNotEmpty) {
      RouterUtil.router(context, RouterPath.USER_RELAYS, relaysTags);
    } else if (isLocal) {
      RouterUtil.router(context, RouterPath.RELAYS);
    }
  }

  onZapTap() {
    if (zapEventBox == null) {
      zapEventBox = EventMemBox(sortAfterAdd: false);
      // pull zap event
      final filter =
          Filter(kinds: [kind.EventKind.ZAP], p: [widget.pubkey], limit: 1);
      pool.querySingle(["wss://relay.nostr.band"], filter).then(
          (final Event? event) {
        if (event == null) return;
        if (event.kind == kind.EventKind.ZAP && zapEventBox!.add(event)) {
          setState(() {
            this.zapNum = this.zapNum! + ZapNumUtil.getNumFromZapEvent(event);
          });
        }
      });

      this.zapNum = 0;
    } else {
      // Router to vist list
      zapEventBox!.sort();
      final list = zapEventBox!.all();
      RouterUtil.router(context, RouterPath.USER_ZAP_LIST, list);
    }
  }

  @override
  void dispose() {
    super.dispose();

    // checkAndUnsubscribe(queryId);
    // checkAndUnsubscribe(queryId2);
  }

  // void checkAndUnsubscribe(String queryId) {
  //   if (StringUtil.isNotBlank(queryId)) {
  //     try {
  //       nostr.unsubscribe(queryId);
  //     } catch (e) {}
  //   }
  // }

  onFollowedCommunitiesTap() {
    if (contactList != null) {
      RouterUtil.router(context, RouterPath.FOLLOWED_COMMUNITIES, contactList);
    } else if (isLocal) {
      final cl = contactListProvider.contactList;
      if (cl != null) {
        RouterUtil.router(context, RouterPath.FOLLOWED_COMMUNITIES, cl);
      }
    }
  }
}

// ignore: must_be_immutable
class UserStatisticsItemComponent extends StatelessWidget {
  UserStatisticsItemComponent({
    required this.num,
    required this.name,
    required this.onTap,
    super.key,
    this.formatNum = false,
    this.onLongPressStart,
  });
  int? num;
  String name;
  Function onTap;
  bool formatNum;
  Function(LongPressStartDetails)? onLongPressStart;

  @override
  Widget build(final BuildContext context) {
    final themeData = Theme.of(context);
    final hintColor = themeData.hintColor;
    final fontSize = themeData.textTheme.bodySmall!.fontSize;

    List<Widget> list = [];
    if (num != null) {
      var numStr = num.toString();
      if (formatNum) {
        numStr = NumberFormatUtil.format(num!);
      }

      list.add(Text(
        numStr,
        style: TextStyle(
          fontSize: fontSize,
        ),
      ));
    } else {
      list.add(const Icon(
        Icons.download,
        size: 14,
      ));
    }
    list.add(Container(
      margin: const EdgeInsets.only(left: 4),
      child: Text(
        name,
        style: TextStyle(
          color: hintColor,
          fontSize: fontSize,
        ),
      ),
    ));

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        onTap();
      },
      onLongPressStart: onLongPressStart,
      child: Container(
        margin: const EdgeInsets.only(left: Base.BASE_PADDING),
        child: Row(children: list),
      ),
    );
  }
}
