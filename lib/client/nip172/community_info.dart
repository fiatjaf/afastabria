import 'package:loure/client/aid.dart';
import 'package:loure/client/event.dart';
import 'package:loure/util/string_util.dart';

import 'package:loure/client/event_kind.dart' as kind;

class CommunityInfo {
  int createdAt;

  AId aId;

  String? description;

  String? image;

  Event? event;

  CommunityInfo({
    required this.createdAt,
    required this.aId,
    this.description,
    this.image,
    this.event,
  });

  static CommunityInfo? fromEvent(Event event) {
    if (event.kind == kind.EventKind.COMMUNITY_DEFINITION) {
      String title = "";
      String description = "";
      String image = "";
      for (var tag in event.tags) {
        if (tag.length > 1) {
          var tagKey = tag[0];
          var tagValue = tag[1];

          if (tagKey == "d") {
            title = tagValue;
          } else if (tagKey == "description") {
            description = tagValue;
          } else if (tagKey == "image") {
            image = tagValue;
          }
        }
      }

      if (StringUtil.isNotBlank(title)) {
        var id = AId(
            kind: kind.EventKind.COMMUNITY_DEFINITION,
            pubkey: event.pubKey,
            title: title);
        return CommunityInfo(
          createdAt: event.createdAt,
          aId: id,
          description: description,
          image: image,
          event: event,
        );
      }
    }

    return null;
  }
}
