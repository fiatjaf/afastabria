import "package:markdown/markdown.dart" as md;

import "package:loure/component/content/markdown/markdown_mention_user_element_builder.dart";

class MarkdownNprofileInlineSyntax extends md.InlineSyntax {
  MarkdownNprofileInlineSyntax() : super("nostr:nprofile[a-zA-Z0-9]+");

  @override
  bool onMatch(final md.InlineParser parser, final Match match) {
    // var text = match.input.substring(match.start, match.end);
    final text = match[0]!;
    final element =
        md.Element.text(MarkdownMentionUserElementBuilder.TAG, text);
    parser.addNode(element);

    return true;
  }
}
