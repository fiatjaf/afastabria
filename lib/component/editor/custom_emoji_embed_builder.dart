import "package:flutter/src/painting/text_style.dart";
import "package:flutter/src/widgets/framework.dart";
import "package:flutter_quill/flutter_quill.dart";
import "package:loure/component/content/content_custom_emoji_component.dart";
import "package:loure/component/editor/cust_embed_types.dart";
import "package:loure/data/custom_emoji.dart";

class CustomEmojiEmbedBuilder extends EmbedBuilder {
  @override
  bool get expanded => false;

  @override
  Widget build(
      final BuildContext context,
      final QuillController controller,
      final Embed node,
      final bool readOnly,
      final bool inline,
      final TextStyle textStyle) {
    final customEmoji = node.value.data as CustomEmoji;
    return ContentCustomEmojiComponent(imagePath: customEmoji.filepath);
  }

  @override
  String get key => CustEmbedTypes.custom_emoji;
}
