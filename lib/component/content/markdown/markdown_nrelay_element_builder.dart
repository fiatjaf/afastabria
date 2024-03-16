import "package:flutter/material.dart";
import "package:markdown/markdown.dart" as md;
import "package:flutter_markdown/flutter_markdown.dart";
import "package:loure/client/nip19/nip19_tlv.dart";
import "package:loure/component/content/content_relay_component.dart";

class MarkdownNrelayElementBuilder implements MarkdownElementBuilder {
  static const String TAG = "relay";

  @override
  Widget? visitElementAfter(
      final md.Element element, final TextStyle? preferredStyle) {
    final pureText = element.textContent;
    final nip19Text = pureText.replaceFirst("nostr:", "");

    String? key;
    if (NIP19Tlv.isNrelay(nip19Text)) {
      final nrelay = NIP19Tlv.decodeNrelay(nip19Text);
      if (nrelay != null) {
        key = nrelay.addr;
      }
    }

    if (key != null) {
      return ContentRelayComponent(key);
    }
    return null;
  }

  @override
  void visitElementBefore(final md.Element element) {}

  @override
  Widget? visitText(final md.Text text, final TextStyle? preferredStyle) {
    return null;
  }

  @override
  Widget? visitElementAfterWithContext(
      final BuildContext context,
      final md.Element element,
      final TextStyle? preferredStyle,
      final TextStyle? parentStyle) {
    return null;
  }
}
