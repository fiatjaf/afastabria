import "package:flutter/widgets.dart";
import "package:flutter_quill/flutter_quill.dart";

import "package:loure/component/event/event_quote_component.dart";
import "package:loure/component/editor/cust_embed_types.dart";

class MentionEventEmbedBuilder extends EmbedBuilder {
  @override
  Widget build(
      final BuildContext context,
      final QuillController controller,
      final Embed node,
      final bool readOnly,
      final bool inline,
      final TextStyle textStyle) {
    final id = node.value.data;
    return AbsorbPointer(
      child: EventQuoteComponent(id: id),
    );
  }

  @override
  String get key => CustEmbedTypes.mention_event;
}
