import "package:flutter/material.dart";

import "package:loure/client/nip58/badge_definition.dart";
import "package:loure/util/string_util.dart";
import "package:loure/component/image_component.dart";

class BedgeComponent extends StatelessWidget {
  BedgeComponent({
    required this.badgeDefinition,
    super.key,
  });
  static const double IMAGE_WIDTH = 28;

  BadgeDefinition badgeDefinition;

  @override
  Widget build(final BuildContext context) {
    var imagePath = badgeDefinition.thumb;
    if (StringUtil.isBlank(imagePath)) {
      imagePath = badgeDefinition.image;
    }

    Widget? imageWidget;
    if (StringUtil.isNotBlank(imagePath)) {
      imageWidget = ImageComponent(
        imageUrl: imagePath!,
        width: IMAGE_WIDTH,
        height: IMAGE_WIDTH,
        fit: BoxFit.cover,
        placeholder: (final context, final url) =>
            const CircularProgressIndicator(),
      );
    }

    final main = Container(
      alignment: Alignment.center,
      height: IMAGE_WIDTH,
      width: IMAGE_WIDTH,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(IMAGE_WIDTH / 2),
        color: Colors.grey,
      ),
      child: imageWidget,
    );

    return main;
  }
}
