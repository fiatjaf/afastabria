import "package:flutter/material.dart";

import "package:loure/client/filter.dart";
import "package:loure/client/input.dart";
import "package:loure/client/relay/relay_pool.dart";
import "package:loure/component/placeholder/event_list_placeholder.dart";
import "package:loure/component/user/metadata_top_component.dart";
import "package:loure/component/event/event_list_component.dart";
import "package:loure/consts/base.dart";
import "package:loure/consts/base_consts.dart";
import "package:loure/data/note_db.dart";
import "package:loure/router/routes.dart";
import "package:loure/main.dart";
import "package:loure/util/debounce.dart";
import "package:loure/util/router_util.dart";

class SearchRouter extends StatefulWidget {
  const SearchRouter({this.query, super.key});

  final String? query;

  @override
  State<StatefulWidget> createState() {
    return SearchRouterState();
  }
}

class SearchRouterState extends State<SearchRouter>
    with AutomaticKeepAliveClientMixin {
  TextEditingController textEditingController = TextEditingController();
  List<Widget> results = [];
  String? isSearching;
  ManySubscriptionHandle? subHandle;
  late final Debounce updateResults;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    if (widget.query != null) {
      this.textEditingController.text = widget.query!;
      this.performSearch();
    }

    this.updateResults = Debounce(const Duration(milliseconds: 500), () {
      this.setState(() {
        this.isSearching = null;
      });
    });
  }

  @override
  void didUpdateWidget(SearchRouter oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.query != oldWidget.query && widget.query != null) {
      this.setState(() {
        this.textEditingController.text = widget.query!;
        this.performSearch();
      });
    }
  }

  void performSearch() async {
    hideKeyBoard();

    final text = this.textEditingController.text;
    if (this.isSearching == text) return;

    // we will start a new search
    if (this.subHandle != null) this.subHandle!.close();

    this.setState(() {
      this.isSearching = text;
      this.results = [];
    });

    final dr = await inputToPointer(text);
    if (dr.pp != null) {
      final pubkey = dr.pp!.pubkey;
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
        this.isSearching = null;
      });
      return;
    }

    if (dr.ep != null) {
      final event = await nostr.getByID(dr.ep!.id, relays: dr.ep!.relays);
      if (event == null) return;
      setState(() {
        this.results = [
          EventListComponent(
            event: event,
            showVideo: settingProvider.videoPreviewInList == OpenStatus.OPEN,
          ),
        ];
        this.isSearching = null;
      });
      return;
    }

    if (dr.ap != null) {
      final event = await nostr.getByAddress(dr.ap!);
      if (event == null) return;
      setState(() {
        this.results = [
          EventListComponent(
            event: event,
            showVideo: settingProvider.videoPreviewInList == OpenStatus.OPEN,
          ),
        ];
        this.isSearching = null;
      });
      return;
    }

    // will do a search on relays
    final filter = Filter(kinds: [1], limit: 15);
    List<String> relays = nostr.TAG_SEARCH_RELAYS;

    for (final part in text.split(" ")) {
      if (part.startsWith("#")) {
        // tag search
        filter.t = filter.t ?? [];
        filter.t!.add(part.substring(1));
      } else {
        // full text search
        relays = nostr.SEARCH_RELAYS;
        filter.search = "${filter.search ?? ""}$part ";
      }
    }

    final Set<String> foundLocally = {};
    if (filter.search != null) {
      // search database first
      this.results = (await NoteDB.search(filter.search!)).map((final event) {
        foundLocally.add(event.id.substring(0, 16));

        return EventListComponent(
          event: event,
          showVideo: settingProvider.videoPreviewInList == OpenStatus.OPEN,
        );
      }).toList();
      this.setState(() {
        this.isSearching = null;
      });
    }

    this.subHandle = pool.subscribeManyEose(
      relays,
      [filter],
      onEvent: (final event) {
        if (foundLocally.contains(event.id.substring(0, 16))) {
          return;
        }

        this.results.add(
              EventListComponent(
                event: event,
                showVideo:
                    settingProvider.videoPreviewInList == OpenStatus.OPEN,
              ),
            );
        updateResults.call();
      },
      onClose: () {
        this.subHandle = null;
      },
    );
    return;
  }

  @override
  Widget build(final BuildContext context) {
    super.build(context);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Column(children: [
        widget.query != null
            ? Padding(
                padding: const EdgeInsets.all(Base.BASE_PADDING),
                child: Text(
                  widget.query!,
                  style: TextStyle(
                    fontSize: Theme.of(context).textTheme.bodyLarge!.fontSize,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
            : TextField(
                controller: textEditingController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: "What are you searching for?",
                  suffixIcon: GestureDetector(
                    onTap: () {
                      textEditingController.text = "";
                      if (this.subHandle != null) {
                        this.subHandle!.close();
                      }
                      this.setState(() {
                        this.results = [];
                        this.isSearching = null;
                      });
                    },
                    child: const Icon(Icons.close),
                  ),
                ),
                onEditingComplete: this.performSearch,
              ),
        Expanded(
          child: this.isSearching != null
              ? const EventListPlaceholder()
              : ListView(children: this.results),
        ),
      ]),
    );
  }

  void hideKeyBoard() {
    final FocusScopeNode currentFocus = FocusScope.of(context);
    if (!currentFocus.hasPrimaryFocus && currentFocus.focusedChild != null) {
      FocusManager.instance.primaryFocus?.unfocus();
    }
  }
}
