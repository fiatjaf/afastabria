import "package:flutter/widgets.dart";
import "package:flutter_quill/flutter_quill.dart";
import "package:loure/component/content/content_lnbc_component.dart";

import "package:loure/component/editor/cust_embed_types.dart";

class LnbcEmbedBuilder extends EmbedBuilder {
  @override
  Widget build(
      final BuildContext context,
      final QuillController controller,
      final Embed node,
      final bool readOnly,
      final bool inline,
      final TextStyle textStyle) {
    final lnbcStr = node.value.data;
    return AbsorbPointer(
      child: ContentLnbcComponent(lnbc: lnbcStr),
    );
  }

  @override
  String get key => CustEmbedTypes.lnbc;
}
