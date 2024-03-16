import "package:flutter/material.dart";
import "package:flutter_quill/flutter_quill.dart";

import "package:loure/component/content/content_mention_user_component.dart";
import "package:loure/component/editor/cust_embed_types.dart";

class MentionUserEmbedBuilder extends EmbedBuilder {
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
    final pubkey = node.value.data;
    return AbsorbPointer(
      child: Container(
        margin: const EdgeInsets.only(
          left: 4,
          right: 4,
        ),
        child: ContentMentionUserComponent(pubkey: pubkey),
      ),
    );
  }

  @override
  String get key => CustEmbedTypes.mention_user;
}
