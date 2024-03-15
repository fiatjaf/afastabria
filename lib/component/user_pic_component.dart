import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:loure/data/metadata.dart';
import 'package:loure/provider/metadata_provider.dart';
import 'package:loure/util/string_util.dart';
import 'package:loure/component/image_component.dart';

class UserPicComponent extends StatefulWidget {
  String pubkey;

  double width;

  UserPicComponent({super.key, 
    required this.pubkey,
    required this.width,
  });

  @override
  State<StatefulWidget> createState() {
    return _UserPicComponent();
  }
}

class _UserPicComponent extends State<UserPicComponent> {
  @override
  Widget build(BuildContext context) {
    return Selector<MetadataProvider, Metadata?>(
      builder: (context, metadata, child) {
        Widget? imageWidget;
        if (metadata != null) {
          if (StringUtil.isNotBlank(metadata.picture)) {
            imageWidget = ImageComponent(
              imageUrl: metadata.picture!,
              width: widget.width,
              height: widget.width,
              fit: BoxFit.cover,
              placeholder: (context, url) => const CircularProgressIndicator(),
            );
          }
        }

        return Container(
          width: widget.width,
          height: widget.width,
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.width / 2),
            color: Colors.grey,
          ),
          child: imageWidget,
        );
      },
      selector: (context, provider) {
        return provider.getMetadata(widget.pubkey);
      },
    );
  }
}
