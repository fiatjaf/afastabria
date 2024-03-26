import "package:easy_debounce/easy_debounce.dart";
import "package:flutter/material.dart";
import "package:hex/hex.dart";
import "package:loure/client/nip19/nip19_tlv.dart";
import "package:loure/component/user/metadata_top_component.dart";
import "package:loure/data/event_find_util.dart";
import "package:loure/data/metadata.dart";
import "package:loure/data/metadata_db.dart";
import "package:loure/router/search/search_action_item_component.dart";
import "package:loure/util/when_stop_function.dart";
import "package:provider/provider.dart";

import "package:loure/client/event.dart";
import "package:loure/client/nip19/nip19.dart";
import "package:loure/client/event_kind.dart";
import "package:loure/client/filter.dart";
import "package:loure/component/event/event_list_component.dart";
import "package:loure/component/event_delete_callback.dart";
import "package:loure/consts/base_consts.dart";
import "package:loure/router/routes.dart";
import "package:loure/data/event_mem_box.dart";
import "package:loure/main.dart";
import "package:loure/provider/setting_provider.dart";
import "package:loure/util/load_more_event.dart";
import "package:loure/util/pendingevents_later_function.dart";
import "package:loure/util/platform_util.dart";
import "package:loure/util/router_util.dart";
import "package:loure/util/string_util.dart";

class SearchRouter extends StatefulWidget {
  const SearchRouter({this.query = "", super.key});

  final String query;

  @override
  State<StatefulWidget> createState() {
    return SearchRouterState();
  }
}

class SearchRouterState extends State<SearchRouter>
    with PendingEventsLaterFunction, LoadMoreEvent, WhenStopFunction {
  TextEditingController textEditingController = TextEditingController();
  ScrollController loadableScrollController = ScrollController();
  ScrollController scrollController = ScrollController();

  List<Widget> results = [];
  static const debounceDuration = Duration(milliseconds: 500);

  @override
  void didUpdateWidget(SearchRouter oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.query != oldWidget.query && widget.query != "") {
      this.setState(() {
        this.textEditingController.text = widget.query;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    bindLoadMoreScroll(loadableScrollController);
    textEditingController.addListener(this.onInput);
  }

  @override
  dispose() {
    super.dispose();
    textEditingController.removeListener(this.onInput);
  }

  void onInput() {
    EasyDebounce.debounce("search", debounceDuration, performSearch);
  }

  void performSearch() async {
    final text = this.textEditingController.text;
    if (text.startsWith("npub1")) {
      final pubkey = NIP19.decode(text);
      final metadata = await metadataLoader.load(pubkey);
      setState(() {
        this.results = [
          GestureDetector(
            onTap: () {
              RouterUtil.router(context, RouterPath.USER, pubkey);
            },
            child: MetadataTopComponent(
              pubkey: pubkey,
              metadata: metadata,
            ),
          ),
        ];
      });
    } else if (text.startsWith("nprofile1")) {
      final nprofile = NIP19.decodeNprofile(text);
      if (nprofile == null) return;
      final pubkey = nprofile.pubkey;
      final metadata = await metadataLoader.load(pubkey);
      setState(() {
        this.results = [
          GestureDetector(
            onTap: () {
              RouterUtil.router(context, RouterPath.USER, pubkey);
            },
            child: MetadataTopComponent(
              pubkey: pubkey,
              metadata: metadata,
            ),
          ),
        ];
      });
    } else if (text.startsWith("note1")) {
      final id = NIP19.decode(text);
      final event = await nostr.getByID(id);
      if (event == null) return;
      setState(() {
        this.results = [
          EventListComponent(
            event: event,
            showVideo: settingProvider.videoPreviewInList == OpenStatus.OPEN,
          ),
        ];
      });
    } else if (text.startsWith("nevent1")) {
      nevent = NIP19.decodeNevent(text);
    } else if (text.startsWith("naddr1")) {
      naddr = NIP19.decodeNaddr(text);
    } else if (text.startsWith("#") && !text.contains(" ")) {
      tag = text.substring(1);
    } else {
      search = text;
    }
  }

  @override
  Widget build(final BuildContext context) {
    preBuild();

    // bool? loadable;
    // Widget? body;
    //   if (searchAction == SearchActions.searchMetadataFromCache) {
    //     loadable = false;
    //     body = ListView.builder(
    //       controller: scrollController,
    //       itemBuilder: (final BuildContext context, final int index) {
    //         final metadata = metadatas[index];

    //         return GestureDetector(
    //           onTap: () {
    //             RouterUtil.router(context, RouterPath.USER, metadata.pubkey);
    //           },
    //           child: MetadataTopComponent(
    //             pubkey: metadata.pubkey,
    //             metadata: metadata,
    //           ),
    //         );
    //       },
    //       itemCount: metadatas.length,
    //     );
    //   } else if (searchAction == SearchActions.searchEventFromCache) {
    //     loadable = false;
    //     body = ListView.builder(
    //       controller: scrollController,
    //       itemBuilder: (final BuildContext context, final int index) {
    //         final event = events[index];

    //         return EventListComponent(
    //           event: event,
    //           showVideo: settingProvider.videoPreviewInList == OpenStatus.OPEN,
    //         );
    //       },
    //       itemCount: events.length,
    //     );
    //   } else if (searchAction == SearchActions.searchPubkeyEvent) {
    //     loadable = true;
    //     final events = eventMemBox.all();
    //     body = ListView.builder(
    //       controller: loadableScrollController,
    //       itemBuilder: (final BuildContext context, final int index) {
    //         final event = events[index];

    //         return EventListComponent(
    //           event: event,
    //           showVideo: settingProvider.videoPreviewInList == OpenStatus.OPEN,
    //         );
    //       },
    //       itemCount: itemLength,
    //     );
    //   }
    // }
    // if (body != null) {
    //   if (loadable != null && PlatformUtil.isTableMode()) {
    //     body = GestureDetector(
    //       onVerticalDragUpdate: (final detail) {
    //         if (loadable == true) {
    //           loadableScrollController
    //               .jumpTo(loadableScrollController.offset - detail.delta.dy);
    //         } else {
    //           scrollController
    //               .jumpTo(scrollController.offset - detail.delta.dy);
    //         }
    //       },
    //       behavior: HitTestBehavior.translucent,
    //       child: body,
    //     );
    //   }
    // } else {
    //   body = Container();
    // }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: EventDeleteCallback(
        onDeleteCallback: onDeletedCallback,
        child: Column(children: [
          TextField(
            controller: textEditingController,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: "What are you searching for?",
              suffixIcon: GestureDetector(
                onTap: () {
                  textEditingController.text = "";
                },
                child: const Icon(Icons.close),
              ),
            ),
            onEditingComplete: onEditingComplete,
          ),
          Expanded(
            child: ListView(
              controller: scrollController,
              children: this.results,
            ),
          ),
        ]),
      ),
    );
  }

  List<int> searchEventKinds = EventKind.SUPPORTED_EVENTS;
  EventMemBox eventMemBox = EventMemBox();

  Filter? filter;

  @override
  void doQuery() {
    preQuery();

    final relays = [...nostr.SEARCH_RELAYS];
    List<Filter> Function(String, List<Filter>)? filterModifier;

    if (!eventMemBox.isEmpty()) {
      final oldestCreatedAts = eventMemBox.oldestCreatedAtByRelay(relays);
      filterModifier = (final url, final filters) {
        filters[0].until = oldestCreatedAts.createdAtMap[url] ?? until;
        return filters;
      };
    }

    pool.querySync(relays, this.filter!, filterModifier: filterModifier);
  }

  void onQueryEvent(final Event event) {
    later(event, (final list) {
      final addResult = eventMemBox.addList(list);
      if (addResult) {
        setState(() {});
      }
    }, null);
  }

  void onEditingComplete() {
    hideKeyBoard();
    searchAction = SearchActions.searchPubkeyEvent;

    var value = controller.text;
    value = value.trim();
    // if (StringUtil.isBlank(value)) {
    //   BotToast.showText(text: "Empty text may be ban by relays");
    // }

    List<String>? authors;
    if (StringUtil.isNotBlank(value) && value.indexOf("npub") == 0) {
      try {
        final result = NIP19.decode(value);
        authors = [result];
      } catch (e) {
        print(e);
        return;
      }
    } else {
      if (StringUtil.isNotBlank(value)) {
        authors = [value];
      }
    }

    eventMemBox = EventMemBox();
    until = null;
    this.filter =
        Filter(kinds: searchEventKinds, authors: authors, limit: queryLimit);
    pendingEvents.clear;
    doQuery();
  }

  void hideKeyBoard() {
    final FocusScopeNode currentFocus = FocusScope.of(context);
    if (!currentFocus.hasPrimaryFocus && currentFocus.focusedChild != null) {
      FocusManager.instance.primaryFocus?.unfocus();
    }
  }

  @override
  EventMemBox getEventBox() {
    return eventMemBox;
  }

  @override
  void dispose() {
    super.dispose();
    disposeLater();
    disposeWhenStop();
  }

  onDeletedCallback(final Event event) {
    eventMemBox.delete(event.id);
    setState(() {});
  }

  openPubkey() {
    hideKeyBoard();
    final text = textEditingController.text;
    if (StringUtil.isNotBlank(text)) {
      String pubkey = text;
      if (NIP19.isPubkey(text)) {
        pubkey = NIP19.decode(text);
      }

      RouterUtil.router(context, RouterPath.USER, pubkey);
    }
  }

  openNoteId() {
    hideKeyBoard();
    final text = controller.text;
    if (StringUtil.isNotBlank(text)) {
      String noteId = text;
      if (NIP19.isNoteId(text)) {
        noteId = NIP19.decode(text);
      }

      RouterUtil.router(context, RouterPath.EVENT_DETAIL, noteId);
    }
  }

  List<Metadata> metadatas = [];

  searchMetadataFromCache() async {
    hideKeyBoard();
    metadatas.clear();
    searchAction = SearchActions.searchMetadataFromCache;

    final text = controller.text;
    if (text.length >= 2) {
      final list = await MetadataDB.search(text);

      setState(() {
        metadatas = list.toList();
      });
    }
  }

  searchEventFromCache() {
    hideKeyBoard();
    events.clear();

    final text = controller.text;
    if (StringUtil.isNotBlank(text)) {
      final list = EventFindUtil.findEvent(text);
      setState(() {
        events = list;
      });
    }
  }

  checkInput() {
    searchAction = null;
    searchAbles.clear();

    final text = controller.text;
    if (text == lastText) {
      return;
    }

    lastText = text;
    setState(() {});
  }

  searchNoteContent() {
    hideKeyBoard();
    searchAction = SearchActions.searchPubkeyEvent;

    var value = controller.text;
    value = value.trim();
    // if (StringUtil.isBlank(value)) {
    //   BotToast.showText(text: "Empty text may be ban by relays");
    // }

    eventMemBox = EventMemBox();
    until = null;
    this.filter =
        Filter(kinds: searchEventKinds, limit: queryLimit, search: value);
    pendingEvents.clear;
    doQuery();
  }
}
