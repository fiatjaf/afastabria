import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:nostrmo/main.dart';
import 'package:nostrmo/util/platform_util.dart';

class ImageComponent extends StatelessWidget {
  String imageUrl;

  double? width;

  double? height;

  BoxFit? fit;

  PlaceholderWidgetBuilder? placeholder;

  ImageComponent({super.key, 
    required this.imageUrl,
    this.width,
    this.height,
    this.fit,
    this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    if (PlatformUtil.isWeb()) {
      // TODO temp handle nostr.build cors error, these should be handled later.
      if (imageUrl.startsWith("https://nostr.build/i/p/")) {
        imageUrl = imageUrl.replaceFirst(
            "https://nostr.build/i/p/", "https://pfp.nostr.build/");
      } else if (imageUrl.startsWith("https://nostr.build/i/")) {
        imageUrl = imageUrl.replaceFirst(
            "https://nostr.build/i/", "https://image.nostr.build/");
      } else if (imageUrl.startsWith("https://cdn.nostr.build/i/")) {
        imageUrl = imageUrl.replaceFirst(
            "https://cdn.nostr.build/i/", "https://image.nostr.build/");
      }
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: placeholder,
      errorWidget: (context, url, error) => const Icon(Icons.error),
      cacheManager: localCacheManager,
      // imageRenderMethodForWeb: ImageRenderMethodForWeb.HttpGet,
    );
  }
}
