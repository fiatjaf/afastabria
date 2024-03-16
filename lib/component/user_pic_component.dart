import 'package:flutter/material.dart';

import 'package:loure/data/metadata.dart';
import 'package:loure/main.dart';
import 'package:loure/component/image_component.dart';

class UserPicComponent extends StatefulWidget {
  final String pubkey;
  final double width;

  const UserPicComponent({
    super.key,
    required this.pubkey,
    required this.width,
  });

  @override
  State<StatefulWidget> createState() {
    return UserPicComponentState();
  }
}

class UserPicComponentState extends State<UserPicComponent> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: metadataLoader.load(widget.pubkey),
      initialData: Metadata.blank(widget.pubkey),
      builder: (context, snapshot) {
        final metadata = snapshot.data!;

        Widget? imageWidget;
        if (metadata.picture != "") {
          imageWidget = ImageComponent(
            imageUrl: metadata.picture!,
            width: widget.width,
            height: widget.width,
            fit: BoxFit.cover,
            placeholder: (context, url) => const CircularProgressIndicator(),
          );
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
    );
  }
}
