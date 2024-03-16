import "package:loure/client/filter.dart";

/// the base aid class.
class AId {
  AId({
    required this.kind,
    required this.pubkey,
    required this.identifier,
  });
  int kind = 0;
  String pubkey = "";
  String identifier = "";

  static AId? fromString(final String text) {
    final strs = text.split(":");
    if (strs.length == 3) {
      final kind = int.tryParse(strs[0]);
      final pubkey = strs[1];
      final identifier = strs[2];

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
