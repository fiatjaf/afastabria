import "dart:convert";

import "package:flutter/material.dart";
import "package:loure/client/event.dart";

import "package:loure/client/nip19/nip19.dart";
import "package:loure/consts/base.dart";
import "package:loure/client/metadata.dart";
import "package:loure/data/db.dart";
import "package:loure/main.dart";
import "package:loure/util/router_util.dart";
import "package:loure/util/string_util.dart";
import "package:loure/util/when_stop_function.dart";
import "package:loure/component/image_component.dart";
import "package:loure/component/editor/search_mention_component.dart";

class SearchMentionUserComponent extends StatefulWidget {
  const SearchMentionUserComponent({super.key});

  @override
  State<StatefulWidget> createState() {
    return _SearchMentionUserComponent();
  }
}

class _SearchMentionUserComponent extends State<SearchMentionUserComponent>
    with WhenStopFunction {
  double itemWidth = 50;

  @override
  Widget build(final BuildContext context) {
    final contentWidth = mediaDataCache.size.width - 4 * Base.BASE_PADDING;
    itemWidth = (contentWidth - 10) / 2;

    return SearchMentionComponent(
      resultBuildFunc: resultBuild,
      handleSearchFunc: handleSearch,
    );
  }

  Widget resultBuild() {
    List<Widget> userWidgetList = [];
    for (final metadata in metadatas) {
      userWidgetList.add(SearchMentionUserItemComponent(
        metadata: metadata,
        width: itemWidth,
      ));
    }
    return SingleChildScrollView(
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.only(
          top: Base.BASE_PADDING_HALF,
          bottom: Base.BASE_PADDING_HALF,
        ),
        child: SizedBox(
          width: itemWidth * 2 + 10,
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: userWidgetList,
          ),
        ),
      ),
    );
  }

  List<Metadata> metadatas = [];

  void handleSearch(final String text) async {
    metadatas.clear();

    if (text.length >= 2) {
      final list = await DB.getDB(null).query("metadata",
          where: "event like '%' || ? || '%' LIMIT 7", whereArgs: [text]);
      setState(() {
        metadatas = list
            .map((final row) => Metadata.fromEvent(
                Event.fromJson(jsonDecode(row["event"] as String))))
            .toList();
      });
    }
  }
}

class SearchMentionUserItemComponent extends StatelessWidget {
  const SearchMentionUserItemComponent({
    required this.metadata,
    required this.width,
    super.key,
  });
  static const double IMAGE_WIDTH = 36;
  final Metadata metadata;
  final double width;

  @override
  Widget build(final BuildContext context) {
    final themeData = Theme.of(context);
    // var mainColor = themeData.primaryColor;
    final cardColor = themeData.cardColor;
    final Color hintColor = themeData.hintColor;

    Widget? imageWidget;
    if (StringUtil.isNotBlank(metadata.picture)) {
      imageWidget = ImageComponent(
        imageUrl: metadata.picture!,
        width: IMAGE_WIDTH,
        height: IMAGE_WIDTH,
        fit: BoxFit.cover,
        placeholder: (final context, final url) =>
            const CircularProgressIndicator(),
      );
    }

    final String nip19Name = NIP19.encodeSimplePubKey(metadata.pubkey);
    String displayName = nip19Name;
    String name = "";
    if (StringUtil.isNotBlank(metadata.displayName)) {
      displayName = metadata.displayName!;
    }
    if (metadata.name != null) {
      name = metadata.name!;
    }

    final main = Container(
      width: width,
      color: cardColor,
      padding: const EdgeInsets.all(Base.BASE_PADDING_HALF),
      child: Row(
        children: [
          Container(
            alignment: Alignment.center,
            height: IMAGE_WIDTH,
            width: IMAGE_WIDTH,
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(IMAGE_WIDTH / 2),
              color: Colors.grey,
            ),
            child: imageWidget,
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.only(left: Base.BASE_PADDING_HALF),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 12,
                      color: hintColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    return GestureDetector(
      onTap: () {
        RouterUtil.back(context, metadata.pubkey);
      },
      child: main,
    );
  }
}
