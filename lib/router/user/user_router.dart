import "package:flutter/material.dart";
import "package:loure/client/client_utils/keys.dart";
import "package:loure/data/metadata.dart";

import "package:loure/client/relay/relay_pool.dart";
import "package:loure/component/simple_name_component.dart";
import "package:loure/client/event_kind.dart";
import "package:loure/client/filter.dart";
import "package:loure/component/appbar4stack.dart";
import "package:loure/component/cust_state.dart";
import "package:loure/component/event/event_list_component.dart";
import "package:loure/component/user/metadata_component.dart";
import "package:loure/consts/base_consts.dart";
import "package:loure/data/event_mem_box.dart";
import "package:loure/main.dart";
import "package:loure/util/load_more_event.dart";
import "package:loure/util/pendingevents_later_function.dart";
import "package:loure/util/router_util.dart";
import "package:loure/router/user/user_statistics_component.dart";

class UserRouter extends StatefulWidget {
  const UserRouter(this.pubkey, {super.key});

  final String pubkey;

  @override
  State<StatefulWidget> createState() {
    return UserRouterState();
  }
}

class UserRouterState extends CustState<UserRouter>
    with PendingEventsLaterFunction, LoadMoreEvent {
  final GlobalKey<NestedScrollViewState> globalKey = GlobalKey();
  final ScrollController _controller = ScrollController();

  bool showTitle = false;
  bool showAppbarBG = false;
  EventMemBox box = EventMemBox();

  /// the offset to show title, bannerHeight + 50;
  double showTitleHeight = 50;

  /// the offset to appbar background color, showTitleHeight + 100;
  double showAppbarBGHeight = 50 + 100;

  @override
  void initState() {
    super.initState();

    queryLimit = 200;
    this.initFromArgs();

    this._controller.addListener(() {
      var showTitle = false;
      var showAppbarBG = false;

      final offset = this._controller.offset;
      if (offset > showTitleHeight) {
        showTitle = true;
      }
      if (offset > showAppbarBGHeight) {
        showAppbarBG = true;
      }

      if (showTitle != showTitle || showAppbarBG != showAppbarBG) {
        setState(() {
          this.showTitle = showTitle;
          this.showAppbarBG = showAppbarBG;
        });
      }
    });
  }

  @override
  void didUpdateWidget(UserRouter oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!keyIsValid(widget.pubkey)) {
      RouterUtil.back(context);
      return;
    }

    if (oldWidget.pubkey == widget.pubkey) {
      // same stuff, do nothing
      return;
    } else {
      // arg change! reset.
      box.clear();
      until = null;
      this.initFromArgs();
    }
  }

  void initFromArgs() {
    final events = followingManager.eventsByPubkey(widget.pubkey);
    if (events.isNotEmpty) {
      box.addList(events.toList());
    }
    doQuery();
    preBuild();
  }

  @override
  Widget doBuild(final BuildContext context) {
    final paddingTop = mediaDataCache.padding.top;
    final maxWidth = mediaDataCache.size.width;

    showTitleHeight = maxWidth / 3 + 50;
    showAppbarBGHeight = showTitleHeight + 100;

    final themeData = Theme.of(context);
    // var cardColor = themeData.cardColor;

    return FutureBuilder(
      future: metadataLoader.load(widget.pubkey),
      initialData: Metadata.blank(widget.pubkey),
      builder: (final context, final snapshot) {
        final metadata = snapshot.data;

        Color? appbarBackgroundColor = Colors.transparent;
        if (showAppbarBG) {
          appbarBackgroundColor = Colors.white.withOpacity(0.6);
        }
        Widget? appbarTitle;
        if (showTitle) {
          final String displayName =
              SimpleNameComponent.getSimpleName(widget.pubkey, metadata);

          appbarTitle = Container(
            alignment: Alignment.center,
            child: Text(
              displayName,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: themeData.textTheme.bodyLarge!.fontSize,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          );
        }
        final appBar = Appbar4Stack(
          backgroundColor: appbarBackgroundColor,
          title: appbarTitle,
        );

        final Widget main = NestedScrollView(
          key: globalKey,
          controller: _controller,
          headerSliverBuilder:
              (final BuildContext context, final bool innerBoxIsScrolled) {
            return <Widget>[
              SliverToBoxAdapter(
                child: MetadataComponent(
                  pubkey: widget.pubkey,
                  metadata: metadata,
                  showBadges: true,
                  userPicturePreview: true,
                ),
              ),
              SliverToBoxAdapter(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: UserStatisticsComponent(
                    pubkey: widget.pubkey,
                  ),
                ),
              ),
            ];
          },
          body: MediaQuery.removePadding(
            removeTop: true,
            context: context,
            child: ListView.builder(
              itemBuilder: (final BuildContext context, final int index) {
                final event = box.get(index);
                if (event == null) {
                  return null;
                }
                return EventListComponent(
                  event: event,
                  showVideo:
                      settingProvider.videoPreviewInList == OpenStatus.OPEN,
                );
              },
              itemCount: box.length(),
            ),
          ),
        );

        return Scaffold(
            body: Stack(
          children: [
            main,
            Positioned(
              top: paddingTop,
              child: SizedBox(
                width: maxWidth,
                child: appBar,
              ),
            ),
          ],
        ));
      },
    );
  }

  ManySubscriptionHandle? subHandle;

  @override
  Future<void> onReady(final BuildContext context) async {
    doQuery();

    if (globalKey.currentState != null) {
      final controller = globalKey.currentState!.innerController;
      controller.addListener(() {
        loadMoreScrollCallback(controller);
      });
    }
  }

  void onEvent(final event) {
    later(event, (final list) {
      box.addList(list);
      setState(() {});
    }, null);
  }

  @override
  void dispose() {
    super.dispose();
    disposeLater();

    if (this.subHandle != null) {
      this.subHandle!.close();
    }
  }

  @override
  void doQuery() {
    preQuery();

    // load event from relay
    final filter = Filter(
      kinds: EventKind.SUPPORTED_EVENTS,
      until: this.until,
      authors: [widget.pubkey],
      limit: this.queryLimit,
    );

    final relays = ["wss://relay.nostr.band"];
    List<Filter> Function(String, List<Filter>)? filterModifier;

    if (!this.box.isEmpty()) {
      final oldestCreatedAts = this.box.oldestCreatedAtByRelay(relays);
      filterModifier = (final url, final filters) {
        filters[0].until = oldestCreatedAts.createdAtMap[url] ?? until;
        return filters;
      };
    }

    pool.querySync(relays, filter, filterModifier: filterModifier);
  }

  @override
  EventMemBox getEventBox() {
    return box;
  }
}
