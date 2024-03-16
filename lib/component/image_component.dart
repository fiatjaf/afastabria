import "package:flutter/material.dart";
import "package:cached_network_image/cached_network_image.dart";

class ImageComponent extends StatelessWidget {
  const ImageComponent({
    required this.imageUrl,
    super.key,
    this.width,
    this.height,
    this.fit,
    this.placeholder,
  });
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final PlaceholderWidgetBuilder? placeholder;

  @override
  Widget build(final BuildContext context) {
    return CachedNetworkImage(
      imageUrl: this.imageUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: placeholder,
      errorWidget: (final context, final url, final error) =>
          const Icon(Icons.error),
    );
  }
}
