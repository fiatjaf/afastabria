import "dart:convert";

import "package:flutter/material.dart";
import "package:get_time_ago/get_time_ago.dart";

import "package:loure/client/event_kind.dart";
import "package:loure/component/name_component.dart";
import "package:loure/consts/router_path.dart";
import "package:loure/main.dart";
import "package:loure/util/router_util.dart";
import "package:loure/util/string_util.dart";
import "package:loure/client/event.dart";
import "package:loure/consts/base.dart";
import "package:loure/data/metadata.dart";
import "package:loure/component/image_component.dart";

class EventTopComponent extends StatefulWidget {
  const EventTopComponent({
    required this.event,
    super.key,
    this.pagePubkey,
  });
  final Event event;
  final String? pagePubkey;

  @override
  State<StatefulWidget> createState() {
    return EventTopComponentState();
  }
}

class EventTopComponentState extends State<EventTopComponent> {
  static const double IMAGE_WIDTH = 34;
  static const double HALF_IMAGE_WIDTH = 17;

  Future<Metadata>? metadataFuture;
  String? pubkey;

  @override
  void initState() {
    super.initState();

    this.pubkey = widget.event.pubKey;

    // if this is the zap event, change the pubkey from the zap tag info
    if (widget.event.kind == EventKind.ZAP) {
      for (final tag in widget.event.tags) {
        if (tag[0] == "description" && widget.event.tags.length > 1) {
          final description = tag[1];
          final jsonMap = jsonDecode(description);
          final sourceEvent = Event.fromJson(jsonMap);
          if (StringUtil.isNotBlank(sourceEvent.pubKey)) {
            this.pubkey = sourceEvent.pubKey;
          }
        }
      }
    }

    this.metadataFuture = metadataLoader.load(this.pubkey!);
  }

  @override
  Widget build(final BuildContext context) {
    if (this.pubkey == null) return Container();

    final themeData = Theme.of(context);
    final smallTextSize = themeData.textTheme.bodySmall!.fontSize;

    return FutureBuilder(
      future: this.metadataFuture,
      initialData: Metadata.blank(this.pubkey!),
      builder: (final context, final snapshot) {
        final metadata = snapshot.data;

        final themeData = Theme.of(context);

        Widget? imageWidget;
        if (metadata != null) {
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
        }

        return Container(
          padding: const EdgeInsets.only(
            left: Base.BASE_PADDING,
            right: Base.BASE_PADDING,
            bottom: Base.BASE_PADDING_HALF,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              jumpWrap(Container(
                width: IMAGE_WIDTH,
                height: IMAGE_WIDTH,
                margin: const EdgeInsets.only(top: 4),
                clipBehavior: Clip.hardEdge,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(HALF_IMAGE_WIDTH),
                  color: Colors.grey,
                ),
                child: imageWidget,
              )),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.only(left: Base.BASE_PADDING_HALF),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        // margin: const EdgeInsets.only(bottom: 2),
                        child: jumpWrap(
                          NameComponent(
                            pubkey: widget.event.pubKey,
                            metadata: metadata,
                            maxLines: 1,
                            textOverflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      Text(
                        GetTimeAgo.parse(DateTime.fromMillisecondsSinceEpoch(
                            widget.event.createdAt * 1000)),
                        style: TextStyle(
                          fontSize: smallTextSize,
                          color: themeData.hintColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget jumpWrap(final Widget c) {
    return GestureDetector(
      onTap: () {
        // disable jump when in same user page.
        if (widget.pagePubkey == widget.event.pubKey) {
          return;
        }

        RouterUtil.router(context, RouterPath.USER, widget.event.pubKey);
      },
      child: c,
    );
  }
}
