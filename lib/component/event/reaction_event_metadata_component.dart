import 'package:flutter/material.dart';
import 'package:loure/consts/router_path.dart';
import 'package:loure/util/router_util.dart';
import 'package:provider/provider.dart';

import 'package:loure/data/metadata.dart';
import 'package:loure/provider/metadata_provider.dart';
import 'package:loure/util/string_util.dart';
import 'package:loure/component/image_component.dart';
import 'package:loure/component/simple_name_component.dart';

class ReactionEventMetadataComponent extends StatefulWidget {
  String pubkey;

  ReactionEventMetadataComponent({super.key, 
    required this.pubkey,
  });

  @override
  State<StatefulWidget> createState() {
    return _ReactionEventMetadataComponent();
  }
}

class _ReactionEventMetadataComponent
    extends State<ReactionEventMetadataComponent> {
  static const double IMAGE_WIDTH = 20;

  @override
  Widget build(BuildContext context) {
    return Selector<MetadataProvider, Metadata?>(
        builder: (context, metadata, child) {
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
            placeholder: (context, url) => const CircularProgressIndicator(),
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
        child: Container(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: list,
          ),
        ),
      );
    }, selector: (context, provider) {
      return provider.getMetadata(widget.pubkey);
    });
  }
}
