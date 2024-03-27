import "package:loure/client/input.dart";
import "package:loure/client/nip19/nip19.dart";

import "package:loure/client/event.dart";

// TODO: rewrite this
/// This class is designed for get the relation from event, but it seam to used for get tagInfo from event before event_main display.
class EventRelation {
  EventRelation.fromEvent(final Event event) {
    id = event.id;
    pubkey = event.pubkey;

    Map<String, int> pMap = {};
    final length = event.tags.length;
    for (var i = 0; i < length; i++) {
      final tag = event.tags[i];

      final mentionStr = "#[$i]";
      if (event.content.contains(mentionStr)) {
        continue;
      }

      final tagLength = tag.length;
      if (tagLength > 1) {
        final tagKey = tag[0];
        final value = tag[1];
        if (tagKey == "p") {
          // check if is Text Note References
          var nip19Str = "nostr:${NIP19.encodePubKey(value)}";
          if (event.content.contains(nip19Str)) {
            continue;
          }
          nip19Str = NIP19.encodeNprofile(ProfilePointer(value, []));
          if (event.content.contains(nip19Str)) {
            continue;
          }

          pMap[value] = 1;
        } else if (tagKey == "e") {
          tagEList.add(value);
          if (tagLength > 3) {
            final marker = tag[3];
            if (marker == "root") {
              rootId = value;
              rootRelayAddr = tag[2];
            } else if (marker == "reply") {
              replyId = value;
              replyRelayAddr = tag[2];
            }
          }
        } else if (tagKey == "subject") {
          subject = value;
        } else if (tagKey == "content-warning") {
          warning = true;
        } else if (tagKey == "a") {
          aId = AddressPointer.fromTag(tag);
        } else if (tagKey == "zapraiser") {
          zapraiser = value;
        } else if (tagKey == "d") {
          dTag = value;
        }
      }
    }

    final tagELength = tagEList.length;
    if (tagELength == 1 && rootId == null && replyId == null) {
      rootId = tagEList[0];
    } else if (tagELength > 1) {
      if (rootId == null && replyId == null) {
        rootId = tagEList.first;
        replyId = tagEList.last;
      } else if (rootId != null && replyId == null) {
        for (var i = tagELength - 1; i > -1; i--) {
          final id = tagEList[i];
          if (id != rootId) {
            replyId = id;
          }
        }
      } else if (rootId == null && replyId != null) {
        for (var i = 0; i < tagELength; i++) {
          final id = tagEList[i];
          if (id != replyId) {
            rootId = id;
          }
        }
      } else {
        rootId ??= tagEList.first;
        replyId ??= tagEList.last;
      }
    }

    if (rootId != null && replyId == rootId && rootRelayAddr == null) {
      rootRelayAddr = replyRelayAddr;
    }

    pMap.remove(event.pubkey);
    tagPList.addAll(pMap.keys);
  }
  late String id;

  late String pubkey;

  List<String> tagPList = [];
  List<String> tagEList = [];

  String? rootId;
  String? rootRelayAddr;
  String? replyId;
  String? replyRelayAddr;
  String? subject;

  bool warning = false;

  AddressPointer? aId;

  String? zapraiser;

  String? dTag;
}
