import "package:bot_toast/bot_toast.dart";
import "package:flutter/material.dart";
import "package:loure/client/nip65/relay_list.dart";

import "package:loure/client/event.dart";
import "package:loure/client/event_kind.dart" as kind;
import "package:loure/client/nip02/contact_list.dart";
import "package:loure/client/filter.dart";
import "package:loure/consts/base.dart";
import "package:loure/router/routes.dart";
import "package:loure/data/event_mem_box.dart";
import "package:loure/main.dart";
import "package:loure/util/number_format_util.dart";
import "package:loure/util/router_util.dart";

class UserStatisticsComponent extends StatefulWidget {
  const UserStatisticsComponent({required this.pubkey, super.key});
  final String pubkey;

  @override
  State<StatefulWidget> createState() {
    return UserStatisticsComponentState();
  }
}

class UserStatisticsComponentState extends State<UserStatisticsComponent> {
  Event? contactListEvent;
  Event? relaysEvent;
  EventMemBox? zapEventBox;
  Map<String, Event>? followedMap;

  int length = 0;
  int relaysNum = 0;
  int? zapNum;
  int? followedNum;

  String? pubkey;

  @override
  void initState() {
    super.initState();
    this.pubkey = widget.pubkey;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (this.pubkey != null && this.pubkey != widget.pubkey) {
      setState(() {
        // arg changed! reset
        this.contactListEvent = null;
        this.relaysEvent = null;
        this.zapEventBox = null;
        this.followedMap = null;

        this.length = 0;
        this.relaysNum = 0;
        this.zapNum = null;
        this.followedNum = null;
      });
    }
  }

  @override
  Widget build(final BuildContext context) {
    pubkey = widget.pubkey;

    return Container(
      // color: Colors.red,
      height: 18,
      margin: const EdgeInsets.only(bottom: Base.BASE_PADDING),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FutureBuilder(
            future: contactListLoader.load(this.pubkey!),
            initialData: ContactList.blank(this.pubkey!),
            builder: (final context, final snapshot) {
              return UserStatisticsItemComponent(
                num: snapshot.data!.contacts.length,
                name: "Following",
                onTap: () {
                  onFollowingTap(snapshot.data!);
                },
                onLongPressStart: onLongPressStart,
              );
            },
          ),
          FutureBuilder(
            future: relaylistLoader.load(this.pubkey!),
            initialData: RelayList.blank(this.pubkey!),
            builder: (final context, final snapshot) {
              return UserStatisticsItemComponent(
                num: snapshot.data!.all.length,
                name: "Relays",
                onTap: () {
                  onRelaysTap(snapshot.data!);
                },
              );
            },
          ),
          UserStatisticsItemComponent(
            num: followedNum,
            name: "Followed",
            onTap: onFollowedTap,
            formatNum: true,
          ),
        ],
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

  onFollowingTap(ContactList cl) {
    RouterUtil.router(context, RouterPath.USER_CONTACT_LIST, cl);
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
    //     var oldEvent = followedMap![e.pubkey];
    //     if (oldEvent == null || e.createdAt > oldEvent.createdAt) {
    //       followedMap![e.pubkey] = e;

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

  onRelaysTap(RelayList rl) {
    RouterUtil.router(context, RouterPath.USER_RELAYS, rl);
  }

  @override
  void dispose() {
    super.dispose();
  }
}

class UserStatisticsItemComponent extends StatelessWidget {
  const UserStatisticsItemComponent({
    required this.num,
    required this.name,
    required this.onTap,
    super.key,
    this.formatNum = false,
    this.onLongPressStart,
  });
  final int? num;
  final String name;
  final Function() onTap;
  final bool formatNum;
  final Function(LongPressStartDetails)? onLongPressStart;

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
      onTap: onTap,
      onLongPressStart: onLongPressStart,
      child: Container(
        margin: const EdgeInsets.only(left: Base.BASE_PADDING),
        child: Row(children: list),
      ),
    );
  }
}
