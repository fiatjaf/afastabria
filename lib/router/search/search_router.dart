import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:nostrmo/component/user/metadata_top_component.dart';
import 'package:nostrmo/data/event_find_util.dart';
import 'package:nostrmo/data/metadata.dart';
import 'package:nostrmo/router/search/search_action_item_component.dart';
import 'package:nostrmo/util/when_stop_function.dart';
import 'package:provider/provider.dart';

import 'package:nostrmo/client/event.dart';
import 'package:nostrmo/client/nip19/nip19.dart';
import 'package:nostrmo/component/cust_state.dart';
import 'package:nostrmo/client/event_kind.dart' as kind;
import 'package:nostrmo/client/filter.dart';
import 'package:nostrmo/component/event/event_list_component.dart';
import 'package:nostrmo/component/event_delete_callback.dart';
import 'package:nostrmo/consts/base_consts.dart';
import 'package:nostrmo/consts/router_path.dart';
import 'package:nostrmo/data/event_mem_box.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/provider/setting_provider.dart';
import 'package:nostrmo/util/load_more_event.dart';
import 'package:nostrmo/util/pendingevents_later_function.dart';
import 'package:nostrmo/util/platform_util.dart';
import 'package:nostrmo/util/router_util.dart';
import 'package:nostrmo/util/string_util.dart';

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
  Future<void> onReady(BuildContext context) async {
    bindLoadMoreScroll(loadableScrollController);

    controller.addListener(() {
      var hasText = StringUtil.isNotBlank(controller.text);
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
  Widget doBuild(BuildContext context) {
    var settingProvider = Provider.of<SettingProvider>(context);
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
      for (var action in searchAbles) {
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
          itemBuilder: (BuildContext context, int index) {
            var metadata = metadatas[index];

            return GestureDetector(
              onTap: () {
                RouterUtil.router(context, RouterPath.USER, metadata.pubKey);
              },
              child: MetadataTopComponent(
                pubkey: metadata.pubKey!,
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
          itemBuilder: (BuildContext context, int index) {
            var event = events[index];

            return EventListComponent(
              event: event,
              showVideo: settingProvider.videoPreviewInList == OpenStatus.OPEN,
            );
          },
          itemCount: events.length,
        );
      } else if (searchAction == SearchActions.searchPubkeyEvent) {
        loadable = true;
        var events = eventMemBox.all();
        body = ListView.builder(
          controller: loadableScrollController,
          itemBuilder: (BuildContext context, int index) {
            var event = events[index];

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
          onVerticalDragUpdate: (detail) {
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

    var relays = [...nostr.SEARCH_RELAYS];
    List<Filter> Function(String, List<Filter>)? filterModifier;

    if (!eventMemBox.isEmpty()) {
      var oldestCreatedAts = eventMemBox.oldestCreatedAtByRelay(relays);
      filterModifier = (url, filters) {
        filters[0].until = oldestCreatedAts.createdAtMap[url] ?? until;
        return filters;
      };
    }

    nostr.pool.querySync(relays, this.filter!, filterModifier: filterModifier);
  }

  void onQueryEvent(Event event) {
    later(event, (list) {
      var addResult = eventMemBox.addList(list);
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
        var result = Nip19.decode(value);
        authors = [result];
      } catch (e) {
        log(e.toString());
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
    FocusScopeNode currentFocus = FocusScope.of(context);
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

  static const int searchMemLimit = 100;

  onDeletedCallback(Event event) {
    eventMemBox.delete(event.id);
    setState(() {});
  }

  openPubkey() {
    hideKeyBoard();
    var text = controller.text;
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
    var text = controller.text;
    if (StringUtil.isNotBlank(text)) {
      String noteId = text;
      if (Nip19.isNoteId(text)) {
        noteId = Nip19.decode(text);
      }

      RouterUtil.router(context, RouterPath.EVENT_DETAIL, noteId);
    }
  }

  List<Metadata> metadatas = [];

  searchMetadataFromCache() {
    hideKeyBoard();
    metadatas.clear();
    searchAction = SearchActions.searchMetadataFromCache;

    var text = controller.text;
    if (StringUtil.isNotBlank(text)) {
      var list = metadataProvider.findUser(text, limit: searchMemLimit);

      setState(() {
        metadatas = list;
      });
    }
  }

  List<Event> events = [];

  searchEventFromCache() {
    hideKeyBoard();
    events.clear();
    searchAction = SearchActions.searchEventFromCache;

    var text = controller.text;
    if (StringUtil.isNotBlank(text)) {
      var list = EventFindUtil.findEvent(text, limit: searchMemLimit);
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

    var text = controller.text;
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
