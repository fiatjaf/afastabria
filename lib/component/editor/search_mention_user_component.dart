import 'package:flutter/material.dart';

import 'package:loure/client/nip19/nip19.dart';
import 'package:loure/consts/base.dart';
import 'package:loure/data/metadata.dart';
import 'package:loure/main.dart';
import 'package:loure/util/router_util.dart';
import 'package:loure/util/string_util.dart';
import 'package:loure/util/when_stop_function.dart';
import 'package:loure/component/image_component.dart';
import 'package:loure/component/editor/search_mention_component.dart';

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
  Widget build(BuildContext context) {
    var contentWidth = mediaDataCache.size.width - 4 * Base.BASE_PADDING;
    itemWidth = (contentWidth - 10) / 2;

    return SaerchMentionComponent(
      resultBuildFunc: resultBuild,
      handleSearchFunc: handleSearch,
    );
  }

  Widget resultBuild() {
    List<Widget> userWidgetList = [];
    for (var metadata in metadatas) {
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

  static const int searchMemLimit = 100;

  List<Metadata> metadatas = [];

  void handleSearch(String? text) {
    metadatas.clear();

    if (StringUtil.isNotBlank(text)) {
      var list = metadataProvider.findUser(text!, limit: searchMemLimit);
      metadatas = list;
    }

    setState(() {});
  }
}

class SearchMentionUserItemComponent extends StatelessWidget {
  static const double IMAGE_WIDTH = 36;

  Metadata metadata;

  double width;

  SearchMentionUserItemComponent({super.key, 
    required this.metadata,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    var themeData = Theme.of(context);
    var mainColor = themeData.primaryColor;
    var cardColor = themeData.cardColor;
    Color hintColor = themeData.hintColor;

    Widget? imageWidget;
    if (StringUtil.isNotBlank(metadata.picture)) {
      imageWidget = ImageComponent(
        imageUrl: metadata.picture!,
        width: IMAGE_WIDTH,
        height: IMAGE_WIDTH,
        fit: BoxFit.cover,
        placeholder: (context, url) => const CircularProgressIndicator(),
      );
    }

    String nip19Name = Nip19.encodeSimplePubKey(metadata.pubKey!);
    String displayName = nip19Name;
    String name = "";
    if (StringUtil.isNotBlank(metadata.displayName)) {
      displayName = metadata.displayName!;
    }
    if (metadata.name != null) {
      name = metadata.name!;
    }

    var main = Container(
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
        RouterUtil.back(context, metadata.pubKey);
      },
      child: main,
    );
  }
}
