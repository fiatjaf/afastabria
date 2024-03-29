import "package:loure/client/event.dart";
import "package:loure/client/filter.dart";
import "package:loure/client/nip05/nip05.dart";
import "package:loure/client/nip19/nip19.dart";

class ProfilePointer {
  const ProfilePointer(this.pubkey, this.relays);

  final String pubkey;
  final List<String> relays;
}

class EventPointer {
  const EventPointer(this.id, this.relays, {this.author, this.kind});

  final String id;
  final List<String> relays;
  final String? author;
  final int? kind;
}

class AddressPointer {
  const AddressPointer(
      {required this.identifier,
      required this.pubkey,
      required this.kind,
      required this.relays});

  final String identifier;
  final String pubkey;
  final int kind;
  final List<String> relays;

  static AddressPointer? fromTag(Tag tag) {
    if (tag.length < 2) return null;

    final strs = tag[1].split(":");
    if (strs.length == 3) {
      final kind = int.tryParse(strs[0], radix: 10);
      final pubkey = strs[1];
      final identifier = strs[2];
      final List<String> relays = tag.length > 2 ? [tag[2]] : [];

      if (kind != null) {
        return AddressPointer(
            kind: kind, pubkey: pubkey, identifier: identifier, relays: relays);
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

Future<DecodeResult?> inputToPointer(String input) async {
  if (input.startsWith("nostr:")) {
    input = input.substring(6);
  }

  if (NIP05.isNIP05(input)) {
    final res = await NIP05.search(input);
    return DecodeResult(res, null, null);
  }

  if (NIP19.isPubkey(input)) {
    return DecodeResult(ProfilePointer(NIP19.decode(input), []), null, null);
  }

  if (NIP19.isNprofile(input)) {
    return DecodeResult(NIP19.decodeNprofile(input), null, null);
  }

  if (NIP19.isNoteId(input)) {
    return DecodeResult(null, EventPointer(NIP19.decode(input), []), null);
  }

  if (NIP19.isNevent(input)) {
    return DecodeResult(null, NIP19.decodeNevent(input), null);
  }

  if (NIP19.isNaddr(input)) {
    return DecodeResult(null, null, NIP19.decodeNaddr(input));
  }

  return null;
}

class DecodeResult {
  const DecodeResult(this.pp, this.ep, this.ap);

  final ProfilePointer? pp;
  final EventPointer? ep;
  final AddressPointer? ap;
}
