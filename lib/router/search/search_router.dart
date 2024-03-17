import "package:flutter/material.dart";
import "package:loure/component/user/metadata_top_component.dart";
import "package:loure/data/event_find_util.dart";
import "package:loure/data/metadata.dart";
import "package:loure/data/metadata_db.dart";
import "package:loure/router/search/search_action_item_component.dart";
import "package:loure/util/when_stop_function.dart";
import "package:provider/provider.dart";

import "package:loure/client/event.dart";
import "package:loure/client/nip19/nip19.dart";
import "package:loure/component/cust_state.dart";
import "package:loure/client/event_kind.dart" as kind;
import "package:loure/client/filter.dart";
import "package:loure/component/event/event_list_component.dart";
import "package:loure/component/event_delete_callback.dart";
import "package:loure/consts/base_consts.dart";
import "package:loure/consts/router_path.dart";
import "package:loure/data/event_mem_box.dart";
import "package:loure/main.dart";
import "package:loure/provider/setting_provider.dart";
import "package:loure/util/load_more_event.dart";
import "package:loure/util/pendingevents_later_function.dart";
import "package:loure/util/platform_util.dart";
import "package:loure/util/router_util.dart";
import "package:loure/util/string_util.dart";

class SearchRouter extends StatefulWidget {
  const SearchRouter({super.key});

  @override
  State<StatefulWidget> createState() {
    return _SearchRouter();
  }
}

class _SearchRouter extends CustState<SearchRouter>
    with PendingEventsLaterFunction, LoadMoreEvent, WhenStopFunction {
  TextEditingController controller = TextEditingController();

  ScrollController loadableScrollController = ScrollController();

  ScrollController scrollController = ScrollController();

  @override
  Future<void> onReady(final BuildContext context) async {
    bindLoadMoreScroll(loadableScrollController);

    controller.addListener(() {
      final hasText = StringUtil.isNotBlank(controller.text);
      if (!showSuffix && hasText) {
        setState(() {
          showSuffix = true;
        });
        return;
      } else if (showSuffix && !hasText) {
        setState(() {
          showSuffix = false;
        });
      }

      whenStop(checkInput);
    });
  }

  bool showSuffix = false;

  @override
  Widget doBuild(final BuildContext context) {
    final settingProvider = Provider.of<SettingProvider>(context);
    preBuild();

    Widget? suffixWidget;
    if (showSuffix) {
      suffixWidget = GestureDetector(
        onTap: () {
          controller.text = "";
        },
        child: const Icon(Icons.close),
      );
    }

    bool? loadable;
    Widget? body;
    if (searchAction == null && searchAbles.isNotEmpty) {
      // no searchAction, show searchAbles
      List<Widget> list = [];
      for (final action in searchAbles) {
        if (action == SearchActions.openPubkey) {
          list.add(SearchActionItemComponent(
              title: "Open User page", onTap: openPubkey));
        } else if (action == SearchActions.openNoteId) {
          list.add(SearchActionItemComponent(
              title: "Open Note detail", onTap: openNoteId));
        } else if (action == SearchActions.searchMetadataFromCache) {
          list.add(SearchActionItemComponent(
              title: "Search User from cache", onTap: searchMetadataFromCache));
        } else if (action == SearchActions.searchEventFromCache) {
          list.add(SearchActionItemComponent(
              title: "Open Event from cache", onTap: searchEventFromCache));
        } else if (action == SearchActions.searchPubkeyEvent) {
          list.add(SearchActionItemComponent(
              title: "Search pubkey event", onTap: onEditingComplete));
        } else if (action == SearchActions.searchNoteContent) {
          list.add(SearchActionItemComponent(
              title: "Search note content NIP-50", onTap: searchNoteContent));
        }
      }
      body = Column(
        mainAxisSize: MainAxisSize.min,
        children: list,
      );
    } else {
      if (searchAction == SearchActions.searchMetadataFromCache) {
        loadable = false;
        body = ListView.builder(
          controller: scrollController,
          itemBuilder: (final BuildContext context, final int index) {
            final metadata = metadatas[index];

            return GestureDetector(
              onTap: () {
                RouterUtil.router(context, RouterPath.USER, metadata.pubkey);
              },
              child: MetadataTopComponent(
                pubkey: metadata.pubkey,
                metadata: metadata,
              ),
            );
          },
          itemCount: metadatas.length,
        );
      } else if (searchAction == SearchActions.searchEventFromCache) {
        loadable = false;
        body = ListView.builder(
          controller: scrollController,
          itemBuilder: (final BuildContext context, final int index) {
            final event = events[index];

            return EventListComponent(
              event: event,
              showVideo: settingProvider.videoPreviewInList == OpenStatus.OPEN,
            );
          },
          itemCount: events.length,
        );
      } else if (searchAction == SearchActions.searchPubkeyEvent) {
        loadable = true;
        final events = eventMemBox.all();
        body = ListView.builder(
          controller: loadableScrollController,
          itemBuilder: (final BuildContext context, final int index) {
            final event = events[index];

            return EventListComponent(
              event: event,
              showVideo: settingProvider.videoPreviewInList == OpenStatus.OPEN,
            );
          },
          itemCount: itemLength,
        );
      }
    }
    if (body != null) {
      if (loadable != null && PlatformUtil.isTableMode()) {
        body = GestureDetector(
          onVerticalDragUpdate: (final detail) {
            if (loadable == true) {
              loadableScrollController
                  .jumpTo(loadableScrollController.offset - detail.delta.dy);
            } else {
              scrollController
                  .jumpTo(scrollController.offset - detail.delta.dy);
            }
          },
          behavior: HitTestBehavior.translucent,
          child: body,
        );
      }
    } else {
      body = Container();
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: EventDeleteCallback(
        onDeleteCallback: onDeletedCallback,
        child: Column(children: [
          TextField(
            controller: controller,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: "Please input search content",
              suffixIcon: suffixWidget,
            ),
            onEditingComplete: onEditingComplete,
          ),
          Expanded(
            child: body,
          ),
        ]),
      ),
    );
  }

  List<int> searchEventKinds = kind.EventKind.SUPPORTED_EVENTS;
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
        final result = Nip19.decode(value);
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
    final text = controller.text;
    if (StringUtil.isNotBlank(text)) {
      String pubkey = text;
      if (Nip19.isPubkey(text)) {
        pubkey = Nip19.decode(text);
      }

      RouterUtil.router(context, RouterPath.USER, pubkey);
    }
  }

  openNoteId() {
    hideKeyBoard();
    final text = controller.text;
    if (StringUtil.isNotBlank(text)) {
      String noteId = text;
      if (Nip19.isNoteId(text)) {
        noteId = Nip19.decode(text);
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

  List<Event> events = [];

  searchEventFromCache() {
    hideKeyBoard();
    events.clear();
    searchAction = SearchActions.searchEventFromCache;

    final text = controller.text;
    if (StringUtil.isNotBlank(text)) {
      final list = EventFindUtil.findEvent(text);
      setState(() {
        events = list;
      });
    }
  }

  String? searchAction;

  List<String> searchAbles = [];

  String lastText = "";

  checkInput() {
    searchAction = null;
    searchAbles.clear();

    final text = controller.text;
    if (text == lastText) {
      return;
    }

    if (StringUtil.isNotBlank(text)) {
      if (Nip19.isPubkey(text)) {
        searchAbles.add(SearchActions.openPubkey);
      }
      if (Nip19.isNoteId(text)) {
        searchAbles.add(SearchActions.openNoteId);
      }
      searchAbles.add(SearchActions.searchMetadataFromCache);
      searchAbles.add(SearchActions.searchEventFromCache);
      searchAbles.add(SearchActions.searchPubkeyEvent);
      searchAbles.add(SearchActions.searchNoteContent);
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

class SearchActions {
  static const String openPubkey = "openPubkey";
  static const String openNoteId = "openNoteId";
  static const String searchMetadataFromCache = "searchMetadataFromCache";
  static const String searchEventFromCache = "searchEventFromCache";
  static const String searchPubkeyEvent = "searchPubkeyEvent";
  static const String searchNoteContent = "searchNoteContent";
}
