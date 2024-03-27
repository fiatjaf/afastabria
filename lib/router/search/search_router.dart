import "package:flutter/material.dart";

import "package:loure/client/filter.dart";
import "package:loure/client/input.dart";
import "package:loure/component/user/metadata_top_component.dart";
import "package:loure/component/event/event_list_component.dart";
import "package:loure/consts/base_consts.dart";
import "package:loure/router/routes.dart";
import "package:loure/main.dart";
import "package:loure/util/router_util.dart";

class SearchRouter extends StatefulWidget {
  const SearchRouter({this.query = "", super.key});

  final String query;

  @override
  State<StatefulWidget> createState() {
    return SearchRouterState();
  }
}

class SearchRouterState extends State<SearchRouter> {
  TextEditingController textEditingController = TextEditingController();
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

  void performSearch() async {
    hideKeyBoard();

    final text = this.textEditingController.text;

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
      });
      return;
    }

    if (text.startsWith("#") && !text.contains(" ")) {
      final tag = text.substring(1);
      final events =
          await pool.querySync(nostr.TAG_SEARCH_RELAYS, Filter(t: [tag]));

      setState(() {
        this.results = events
            .map(
              (event) => EventListComponent(
                event: event,
                showVideo:
                    settingProvider.videoPreviewInList == OpenStatus.OPEN,
              ),
            )
            .toList();
      });
      return;
    }

    final events = await pool.querySync(nostr.SEARCH_RELAYS, Filter(t: [text]));
    setState(() {
      this.results = events
          .map(
            (event) => EventListComponent(
              event: event,
              showVideo: settingProvider.videoPreviewInList == OpenStatus.OPEN,
            ),
          )
          .toList();
    });
    return;
  }

  @override
  Widget build(final BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Column(children: [
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
          onEditingComplete: performSearch,
        ),
        Expanded(
          child: ListView(
            children: this.results,
          ),
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
