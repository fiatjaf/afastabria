import "package:flutter/material.dart";
import "package:markdown/markdown.dart" as md;
import "package:flutter_markdown/flutter_markdown.dart";
import "package:loure/client/nip19/nip19.dart";
import "package:loure/client/nip19/nip19_tlv.dart";
import "package:loure/component/content/content_mention_user_component.dart";

class MarkdownMentionUserElementBuilder implements MarkdownElementBuilder {
  static const String TAG = "mentionUser";

  @override
  Widget? visitElementAfter(
      final md.Element element, final TextStyle? preferredStyle) {
    final pureText = element.textContent;
    final nip19Text = pureText.replaceFirst("nostr:", "");

    String? key;
    if (Nip19.isPubkey(nip19Text)) {
      key = Nip19.decode(nip19Text);
    } else if (NIP19Tlv.isNprofile(nip19Text)) {
      final nprofile = NIP19Tlv.decodeNprofile(nip19Text);
      if (nprofile != null) {
        key = nprofile.pubkey;
      }
    }

    if (key != null) {
      return ContentMentionUserComponent(pubkey: key);
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
