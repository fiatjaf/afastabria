import 'package:flutter/material.dart';
import 'package:loure/component/content/content_component.dart';

import 'package:loure/consts/base.dart';
import 'package:loure/data/metadata.dart';
import 'package:loure/util/string_util.dart';
import 'package:loure/component/user/metadata_top_component.dart';
import 'package:loure/component/user/user_badges_component.dart';

class MetadataComponent extends StatefulWidget {
  String pubKey;

  Metadata? metadata;

  bool jumpable;

  bool showBadges;

  bool userPicturePreview;

  MetadataComponent({super.key, 
    required this.pubKey,
    this.metadata,
    this.jumpable = false,
    this.showBadges = false,
    this.userPicturePreview = false,
  });

  @override
  State<StatefulWidget> createState() {
    return _MetadataComponent();
  }
}

class _MetadataComponent extends State<MetadataComponent> {
  @override
  Widget build(BuildContext context) {
    List<Widget> mainList = [];

    mainList.add(MetadataTopComponent(
      pubkey: widget.pubKey,
      metadata: widget.metadata,
      jumpable: widget.jumpable,
      userPicturePreview: widget.userPicturePreview,
    ));

    if (widget.showBadges) {
      mainList.add(UserBadgesComponent(
        key: Key("ubc_${widget.pubKey}"),
        pubkey: widget.pubKey,
      ));
    }

    if (widget.metadata != null &&
        StringUtil.isNotBlank(widget.metadata!.about)) {
      mainList.add(
        Container(
          width: double.maxFinite,
          padding: const EdgeInsets.only(
            top: Base.BASE_PADDING_HALF,
            left: Base.BASE_PADDING,
            right: Base.BASE_PADDING,
            bottom: Base.BASE_PADDING,
          ),
          // child: Text(widget.metadata!.about!),
          child: SizedBox(
            width: double.maxFinite,
            child: ContentComponent(
              content: widget.metadata!.about,
              // TODO this should add source event
              showLinkPreview: false,
            ),
            // child: Column(
            //   crossAxisAlignment: CrossAxisAlignment.start,
            //   mainAxisSize: MainAxisSize.min,
            //   children: ContentDecoder.decode(
            //     context,
            //     widget.metadata!.about!,
            //     null,
            //     showLinkPreview: false,
            //   ),
            // ),
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: mainList,
    );
  }
}
