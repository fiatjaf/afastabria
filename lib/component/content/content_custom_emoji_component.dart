import 'dart:io';

import 'package:flutter/material.dart';

import '../image_component.dart';

class ContentCustomEmojiComponent extends StatelessWidget {
  final String imagePath;

  const ContentCustomEmojiComponent({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    // var themeData = Theme.of(context);
    // var fontSize = themeData.textTheme.bodyMedium!.fontSize;
    if (imagePath.indexOf("http") == 0) {
      // netword image
      return Container(
        constraints: const BoxConstraints(maxWidth: 80, maxHeight: 80),
        child: ImageComponent(
          // width: fontSize! * 2,
          imageUrl: imagePath,
          // fit: imageBoxFix,
          placeholder: (context, url) => Container(),
        ),
      );
    } else {
      // local image
      return Container(
        constraints: const BoxConstraints(maxWidth: 80, maxHeight: 80),
        child: Image.file(
          File(imagePath),
          // fit: BoxFit.fitWidth,
        ),
      );
    }
  }
}
