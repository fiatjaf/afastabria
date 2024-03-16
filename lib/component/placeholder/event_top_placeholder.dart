import "package:flutter/material.dart";
import "package:flutter_placeholder_textlines/placeholder_lines.dart";

import "package:loure/consts/base.dart";

class EventTopPlaceholder extends StatelessWidget {
  const EventTopPlaceholder({super.key});
  static const double IMAGE_WIDTH = 34;

  static const double HALF_IMAGE_WIDTH = 17;
  @override
  Widget build(final BuildContext context) {
    final themeData = Theme.of(context);
    final hintColor = themeData.hintColor;
    final textSize = themeData.textTheme.bodyMedium!.fontSize;
    final smallTextSize = themeData.textTheme.bodySmall!.fontSize;

    return Container(
      padding: const EdgeInsets.only(
        left: Base.BASE_PADDING,
        right: Base.BASE_PADDING,
        bottom: Base.BASE_PADDING_HALF,
      ),
      child: Row(
        children: [
          Container(
            width: IMAGE_WIDTH,
            height: IMAGE_WIDTH,
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(HALF_IMAGE_WIDTH),
              color: hintColor,
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.only(left: Base.BASE_PADDING_HALF),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    width: 100,
                    child: PlaceholderLines(
                      count: 1,
                      lineHeight: textSize!,
                      color: hintColor,
                    ),
                  ),
                  SizedBox(
                    width: 50,
                    child: PlaceholderLines(
                      count: 1,
                      lineHeight: smallTextSize!,
                      color: hintColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
