import "package:flutter/material.dart";

class MediaDataCache {
  late Size size;

  late EdgeInsets padding;

  void update(final BuildContext context) {
    final mediaData = MediaQuery.of(context);
    size = mediaData.size;
    padding = mediaData.padding;
  }
}
