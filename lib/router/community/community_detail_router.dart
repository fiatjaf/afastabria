import "package:flutter/material.dart";
import "package:loure/client/input.dart";
import "package:loure/client/relay/relay_pool.dart";
import "package:loure/component/community_info_component.dart";
import "package:loure/consts/base.dart";
import "package:loure/provider/community_info_provider.dart";
import "package:provider/provider.dart";
import "package:widget_size/widget_size.dart";

import "package:loure/client/event.dart";
import "package:loure/client/nip172/community_info.dart";
import "package:loure/component/cust_state.dart";
import "package:loure/component/event/event_list_component.dart";
import "package:loure/component/event_delete_callback.dart";
import "package:loure/consts/base_consts.dart";
import "package:loure/data/event_mem_box.dart";
import "package:loure/main.dart";
import "package:loure/provider/setting_provider.dart";
import "package:loure/util/pendingevents_later_function.dart";
import "package:loure/util/router_util.dart";
import "package:loure/router/edit/editor_router.dart";

class CommunityDetailRouter extends StatefulWidget {
  const CommunityDetailRouter({super.key});

  @override
  State<StatefulWidget> createState() {
    return _CommunityDetailRouter();
  }
}

class _CommunityDetailRouter extends CustState<CommunityDetailRouter>
    with PendingEventsLaterFunction {
  EventMemBox box = EventMemBox();

  final ScrollController _controller = ScrollController();
  bool showTitle = false;
  double infoHeight = 80;
  AddressPointer? aId;
  ManySubscriptionHandle? subHandle;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      if (_controller.offset > infoHeight * 0.8 && !showTitle) {
        setState(() {
          showTitle = true;
        });
      } else if (_controller.offset < infoHeight * 0.8 && showTitle) {
        setState(() {
          showTitle = false;
        });
      }
    });
  }

  @override
  Widget doBuild(final BuildContext context) {
    if (aId == null) {
      final arg = RouterUtil.routerArgs(context);
      if (arg != null) {
        aId = arg as AddressPointer;
      }
    }
    if (aId == null) {
      RouterUtil.back(context);
      return Container();
    }
    final settingProvider = Provider.of<SettingProvider>(context);
    final themeData = Theme.of(context);
    final bodyLargeFontSize = themeData.textTheme.bodyLarge!.fontSize;

    Widget? appBarTitle;
    if (showTitle) {
      appBarTitle = Text(
        aId!.identifier,
        style: TextStyle(
          fontSize: bodyLargeFontSize,
          overflow: TextOverflow.ellipsis,
        ),
      );
    }

    final Widget main = EventDeleteCallback(
      onDeleteCallback: onDeleteCallback,
      child: ListView.builder(
        controller: _controller,
        itemBuilder: (final context, final index) {
          if (index == 0) {
            return Selector<CommunityInfoProvider, CommunityInfo?>(
                builder: (final context, final info, final child) {
              if (info == null) {
                return Container();
              }

              return WidgetSize(
                onChange: (final s) {
                  infoHeight = s.height;
                },
                child: CommunityInfoComponent(info: info),
              );
            }, selector: (final context, final provider) {
              return provider.getCommunity(aId!.toTag());
            });
          }

          final event = box.get(index - 1);
          if (event == null) {
            return null;
          }

          return EventListComponent(
            event: event,
            showVideo: settingProvider.videoPreviewInList == OpenStatus.OPEN,
            showCommunity: false,
          );
        },
        itemCount: box.length() + 1,
      ),
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
        actions: [
          GestureDetector(
            onTap: addToCommunity,
            child: Container(
              margin: const EdgeInsets.only(
                left: Base.BASE_PADDING,
                right: Base.BASE_PADDING,
              ),
              child: Icon(
                Icons.add,
                color: themeData.appBarTheme.titleTextStyle!.color,
              ),
            ),
          )
        ],
        title: appBarTitle,
      ),
      body: main,
    );
  }

  // CommunityInfo? communityInfo;

  @override
  Future<void> onReady(final BuildContext context) async {
    if (aId != null) {
      // {
      //   var filter = Filter(kinds: [
      //     EventKind.COMMUNITY_DEFINITION,
      //   ], authors: [
      //     aId!.pubkey
      //   ], limit: 1);
      //   var queryArg = filter.toJson();
      //   queryArg["#d"] = [aId!.title];
      //   nostr!.query([queryArg], (e) {
      //     if (communityInfo == null || communityInfo!.createdAt < e.createdAt) {
      //       var ci = CommunityInfo.fromEvent(e);
      //       if (ci != null) {
      //         setState(() {
      //           communityInfo = ci;
      //         });
      //       }
      //     }
      //   }, id: infoSubscribeId);
      // }
      queryEvents();
    }
  }

  void queryEvents() {
    if (this.aId == null) return;
    this.subHandle = pool.subscribeManyEose(
        ["wss://relay.nostr.band"], [this.aId!.toFilter()],
        onEvent: onEvent);
  }

  void onEvent(final Event event) {
    later(event, (final list) {
      box.addList(list);
      setState(() {});
    }, null);
  }

  @override
  void dispose() {
    super.dispose();
    disposeLater();

    if (this.subHandle != null) this.subHandle!.close();
  }

  onDeleteCallback(final Event event) {
    box.delete(event.id);
    setState(() {});
  }

  Future<void> addToCommunity() async {
    if (aId != null) {
      /*final event = await*/ EditorRouter.open(context, tags: [
        ["a", aId!.toTag()]
      ]);
      /*if (event != null) {
        queryEvents();
      }*/
    }
  }
}
