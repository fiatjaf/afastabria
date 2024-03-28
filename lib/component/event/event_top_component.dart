import "package:flutter/material.dart";
import "package:get_time_ago/get_time_ago.dart";

import "package:loure/component/name_component.dart";
import "package:loure/router/routes.dart";
import "package:loure/main.dart";
import "package:loure/util/router_util.dart";
import "package:loure/util/string_util.dart";
import "package:loure/client/event.dart";
import "package:loure/consts/base.dart";
import "package:loure/client/metadata.dart";
import "package:loure/component/image_component.dart";

class EventTopComponent extends StatelessWidget {
  const EventTopComponent({
    required this.event,
    super.key,
  });
  final Event event;

  static const double IMAGE_WIDTH = 34;
  static const double HALF_IMAGE_WIDTH = 17;

  @override
  Widget build(final BuildContext context) {
    // if this is a zap event, change the pubkey from the zap tag info
    // if (this.event.kind == EventKind.ZAP) {
    //   for (final tag in this.event.tags) {
    //     if (tag[0] == "description" && this.event.tags.length > 1) {
    //       final description = tag[1];
    //       final jsonMap = jsonDecode(description);
    //       final sourceEvent = Event.fromJson(jsonMap);
    //       if (StringUtil.isNotBlank(sourceEvent.pubkey)) {
    //         pubkey = sourceEvent.pubkey;
    //       }
    //     }
    //   }
    // }

    final themeData = Theme.of(context);
    final smallTextSize = themeData.textTheme.bodySmall!.fontSize;

    return FutureBuilder(
      future: metadataLoader.load(this.event.pubkey),
      initialData: Metadata.blank(this.event.pubkey),
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
              jumpWrap(
                  context,
                  Container(
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
                          context,
                          NameComponent(
                            pubkey: this.event.pubkey,
                            metadata: metadata,
                            maxLines: 1,
                            textOverflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      Text(
                        GetTimeAgo.parse(DateTime.fromMillisecondsSinceEpoch(
                            this.event.createdAt * 1000)),
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

  Widget jumpWrap(final BuildContext context, final Widget c) {
    return GestureDetector(
      onTap: () {
        RouterUtil.router(context, RouterPath.USER, this.event.pubkey);
      },
      child: c,
    );
  }
}
