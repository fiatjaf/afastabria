import "package:flutter/material.dart";
import "package:flutter_placeholder_textlines/placeholder_lines.dart";

import "package:loure/consts/base.dart";
import "package:loure/component/placeholder/event_top_placeholder.dart";

class EventPlaceholder extends StatelessWidget {
  const EventPlaceholder({super.key});

  @override
  Widget build(final BuildContext context) {
    final themeData = Theme.of(context);
    final hintColor = themeData.hintColor;
    final smallTextSize = themeData.textTheme.bodySmall!.fontSize;
    final cardColor = themeData.cardColor;

    const textLineMagin = EdgeInsets.only(bottom: 3);

    final main = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        const EventTopPlaceholder(),
        Container(
          width: double.maxFinite,
          padding: const EdgeInsets.only(
            left: Base.BASE_PADDING,
            right: Base.BASE_PADDING,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: textLineMagin,
                child: PlaceholderLines(
                  count: 1,
                  lineHeight: smallTextSize!,
                  color: hintColor,
                ),
              ),
              Container(
                margin: textLineMagin,
                child: PlaceholderLines(
                  count: 1,
                  lineHeight: smallTextSize,
                  color: hintColor,
                ),
              ),
              Container(
                margin: textLineMagin,
                child: PlaceholderLines(
                  count: 1,
                  lineHeight: smallTextSize,
                  color: hintColor,
                ),
              ),
              Container(
                width: 200,
                margin: textLineMagin,
                child: PlaceholderLines(
                  count: 1,
                  lineHeight: smallTextSize,
                  color: hintColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    return Container(
      padding: const EdgeInsets.only(
        top: Base.BASE_PADDING,
        bottom: Base.BASE_PADDING,
      ),
      margin: const EdgeInsets.only(bottom: Base.BASE_PADDING_HALF),
      color: cardColor,
      child: main,
    );
  }
}
