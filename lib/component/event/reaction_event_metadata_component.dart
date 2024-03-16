import 'package:flutter/material.dart';
import 'package:loure/consts/router_path.dart';
import 'package:loure/main.dart';
import 'package:loure/util/router_util.dart';

import 'package:loure/data/metadata.dart';
import 'package:loure/util/string_util.dart';
import 'package:loure/component/image_component.dart';
import 'package:loure/component/simple_name_component.dart';

class ReactionEventMetadataComponent extends StatefulWidget {
  final String pubkey;

  const ReactionEventMetadataComponent({
    super.key,
    required this.pubkey,
  });

  @override
  State<StatefulWidget> createState() {
    return ReactionEventMetadataComponentState();
  }
}

class ReactionEventMetadataComponentState
    extends State<ReactionEventMetadataComponent> {
  static const double IMAGE_WIDTH = 20;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: metadataLoader.load(widget.pubkey),
        initialData: Metadata.blank(widget.pubkey),
        builder: (context, snapshot) {
          final metadata = snapshot.data;

          List<Widget> list = [];

          var name = SimpleNameComponent.getSimpleName(widget.pubkey, metadata);

          Widget? imageWidget;
          if (metadata != null) {
            if (StringUtil.isNotBlank(metadata.picture)) {
              imageWidget = ImageComponent(
                imageUrl: metadata.picture!,
                width: IMAGE_WIDTH,
                height: IMAGE_WIDTH,
                fit: BoxFit.cover,
                placeholder: (context, url) =>
                    const CircularProgressIndicator(),
              );
            }
          }

          list.add(Container(
            width: IMAGE_WIDTH,
            height: IMAGE_WIDTH,
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(IMAGE_WIDTH / 2),
              color: Colors.grey,
            ),
            child: imageWidget,
          ));

          list.add(Container(
            margin: const EdgeInsets.only(left: 5),
            child: Text(
              name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ));

          return GestureDetector(
            onTap: () {
              RouterUtil.router(context, RouterPath.USER, widget.pubkey);
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: list,
            ),
          );
        });
  }
}
