import "dart:io";

import "package:flutter/material.dart";
import "package:flutter_quill/flutter_quill.dart";
import "package:loure/consts/base64.dart";

import "package:loure/component/image_component.dart";

class PicEmbedBuilder extends EmbedBuilder {
  @override
  Widget build(
      final BuildContext context,
      final QuillController controller,
      final Embed node,
      final bool readOnly,
      final bool inline,
      final TextStyle textStyle) {
    final imageUrl = node.value.data as String;
    if (imageUrl.indexOf("http") == 0 || imageUrl.indexOf(BASE64.PREFIX) == 0) {
      // netword image
      return ImageComponent(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        placeholder: (final context, final url) =>
            const CircularProgressIndicator(),
      );
    } else {
      // local image
      return Image.file(
        File(imageUrl),
        fit: BoxFit.cover,
      );
    }
  }

  @override
  String get key => BlockEmbed.imageType;
}
