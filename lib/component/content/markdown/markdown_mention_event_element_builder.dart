import "package:flutter/material.dart";
import "package:markdown/markdown.dart" as md;
import "package:flutter_markdown/flutter_markdown.dart";
import "package:loure/client/nip19/nip19.dart";
import "package:loure/component/event/event_quote_component.dart";

class MarkdownMentionEventElementBuilder implements MarkdownElementBuilder {
  static const String TAG = "mentionEvent";

  @override
  Widget? visitElementAfter(
      final md.Element element, final TextStyle? preferredStyle) {
    final pureText = element.textContent;
    final nip19Text = pureText.replaceFirst("nostr:", "");

    String? key;

    if (NIP19.isNoteId(nip19Text)) {
      key = NIP19.decode(nip19Text);
    } else if (NIP19.isNevent(nip19Text)) {
      final nevent = NIP19.decodeNevent(nip19Text);
      if (nevent != null) {
        print(nevent.relays);
        key = nevent.id;
      }
    } else if (NIP19.isNaddr(nip19Text)) {
      final naddr = NIP19.decodeNaddr(nip19Text);
      if (naddr != null) {
        print(naddr.relays);
        key = naddr.identifier;
      }
    }

    if (key != null) {
      return EventQuoteComponent(
        id: key,
      );
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
