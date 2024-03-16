import 'package:loure/client/filter.dart';

/// the base aid class.
class AId {
  int kind = 0;
  String pubkey = "";
  String identifier = "";

  AId({
    required this.kind,
    required this.pubkey,
    required this.identifier,
  });

  static AId? fromString(String text) {
    var strs = text.split(":");
    if (strs.length == 3) {
      var kind = int.tryParse(strs[0]);
      var pubkey = strs[1];
      var identifier = strs[2];

      if (kind != null) {
        return AId(kind: kind, pubkey: pubkey, identifier: identifier);
      }
    }

    return null;
  }

  String toTag() {
    return "$kind:$pubkey:$identifier";
  }

  Filter toFilter() {
    return Filter(authors: [pubkey], kinds: [kind], d: [identifier]);
  }
}
