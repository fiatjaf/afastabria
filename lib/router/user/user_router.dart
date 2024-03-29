import "package:flutter/material.dart";
import "package:loure/client/event.dart";
import "package:loure/client/metadata.dart";

import "package:loure/client/relay/relay_pool.dart";
import "package:loure/component/simple_name_component.dart";
import "package:loure/client/event_kind.dart";
import "package:loure/client/filter.dart";
import "package:loure/component/appbar4stack.dart";
import "package:loure/component/event/event_list_component.dart";
import "package:loure/component/user/metadata_component.dart";
import "package:loure/consts/base_consts.dart";
import "package:loure/data/db.dart";
import "package:loure/main.dart";
import "package:loure/util/debounce.dart";
import "package:loure/router/user/user_statistics_component.dart";

class UserRouter extends StatefulWidget {
  const UserRouter(this.pubkey, {super.key});

  final String pubkey;

  @override
  State<StatefulWidget> createState() {
    return UserRouterState();
  }
}

class UserRouterState extends State<UserRouter> {
  final GlobalKey<NestedScrollViewState> globalKey = GlobalKey();
  final ScrollController scrollController = ScrollController();

  bool isFollowed = false;
  List<Event> events = [];
  ManySubscriptionHandle? subHandle;

  List<Event> pending = [];
  late final Debounce processPending;

  bool showTitle = false;
  bool showAppbarBG = false;

  /// the offset to show title, bannerHeight + 50;
  double showTitleHeight = 50;

  /// the offset to appbar background color, showTitleHeight + 100;
  double showAppbarBGHeight = 50 + 100;

  @override
  void initState() {
    super.initState();

    this.processPending =
        Debounce(const Duration(milliseconds: 500), this.processEvents);

    this.initFromArgs();

    this.scrollController.addListener(() {
      final offset = this.scrollController.offset;

      if (showTitle != showTitle || showAppbarBG != showAppbarBG) {
        setState(() {
          if (offset > showTitleHeight) {
            this.showTitle = true;
          }
          if (offset > showAppbarBGHeight) {
            this.showAppbarBG = true;
          }
        });
      }

      if (this.scrollController.position.maxScrollExtent - offset < 1000) {
        this.loadOlderEvents();
      }
    });
  }

  @override
  void didUpdateWidget(UserRouter oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.pubkey == widget.pubkey) {
      // same stuff, do nothing
      return;
    } else {
      // arg change! reset.
      this.initFromArgs();
    }
  }

  @override
  Widget build(final BuildContext context) {
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
            child: Scrollbar(
              controller: this.scrollController,
              child: ListView.builder(
                controller: this.scrollController,
                itemBuilder: (final BuildContext context, final int index) {
                  return EventListComponent(
                    event: this.events[index],
                    showVideo:
                        settingProvider.videoPreviewInList == OpenStatus.OPEN,
                  );
                },
                itemCount: this.events.length,
              ),
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

  void initFromArgs() async {
    setState(() {
      this.events = followingManager.eventsByPubkey(widget.pubkey).toList();
      this.isFollowed = contactListProvider.getContact(widget.pubkey) != null;
    });

    final filter = Filter(
      kinds: EventKind.SUPPORTED_EVENTS,
      authors: [widget.pubkey],
      // until: this.until,
      limit: 100,
    );

    final relays = await nostr.getUserOutboxRelays(widget.pubkey);
    List<Filter> Function(String, List<Filter>)? filterModifier;

    // if (!this.box.isEmpty()) {
    //   final oldestCreatedAts = this.box.oldestCreatedAtByRelay(relays);
    //   filterModifier = (final url, final filters) {
    //     filters[0].until = oldestCreatedAts.createdAtMap[url] ?? until;
    //     return filters;
    //   };
    // }

    this.subHandle = pool.subscribeMany(relays, [filter],
        filterModifier: filterModifier, onEvent: onEvent);
  }

  loadOlderEvents() {
    // TODO
  }

  onEvent(final Event event) {
    this.pending.add(event);
    this.processPending.call();
  }

  processEvents() async {
    this.setState(() {
      this.events.addAll(this.pending);
      this.events.sort((final a, final b) => b.createdAt - a.createdAt);
    });
    await DB.transaction((final txn) async {
      for (final event in this.pending) {
        await nostr.processDownloadedEvent(event,
            followed: this.isFollowed, db: txn);
      }
    });
    this.pending = [];
  }

  @override
  void dispose() {
    super.dispose();

    if (this.subHandle != null) this.subHandle!.close();
  }
}
