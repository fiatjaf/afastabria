import "package:loure/util/string_util.dart";
import "package:loure/client/event.dart";
import "package:loure/client/event_kind.dart" as kind;

class BadgeDefinition {
  BadgeDefinition(this.pubkey, this.d, this.updatedAt,
      {this.name, this.description, this.image, this.thumb});
  final String pubkey;

  final String d;

  final String? name;

  final String? description;

  final String? image;

  final String? thumb;

  final int updatedAt;

  static BadgeDefinition? loadFromEvent(final Event event) {
    final String pubkey = event.pubkey;
    String? d;
    String? name;
    String? description;
    String? image;
    String? thumb;

    if (event.kind == kind.EventKind.BADGE_DEFINITION) {
      for (final tag in event.tags) {
        if (tag.length > 1) {
          final key = tag[0];
          final value = tag[1];
          if (key == "d") {
            d = value;
          } else if (key == "name") {
            name = value;
          } else if (key == "description") {
            description = value;
          } else if (key == "image") {
            image = value;
          } else if (key == "thumb") {
            thumb = value;
          }
        }
      }

      if (StringUtil.isNotBlank(d)) {
        return BadgeDefinition(pubkey, d!, event.createdAt,
            name: name, description: description, image: image, thumb: thumb);
      }
    }
    return null;
  }
}
