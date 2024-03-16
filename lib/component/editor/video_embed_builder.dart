import "package:flutter/material.dart";
import "package:flutter_quill/flutter_quill.dart";

import "package:loure/component/content/content_video_component.dart";

class VideoEmbedBuilder extends EmbedBuilder {
  @override
  Widget build(
      final BuildContext context,
      final QuillController controller,
      final Embed node,
      final bool readOnly,
      final bool inline,
      final TextStyle textStyle) {
    final url = node.value.data as String;
    return ContentVideoComponent(url: url);
  }

  @override
  String get key => BlockEmbed.videoType;
}
