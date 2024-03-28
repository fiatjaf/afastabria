import "dart:convert";

import "package:loure/client/event.dart";
import "package:loure/client/nip05/nip05.dart";
import "package:loure/client/replaceable_loader.dart";

class Metadata extends Replaceable {
  Metadata(
    this.event, {
    final String? pubkey,
    this.name,
    this.displayName,
    this.picture,
    this.banner,
    this.website,
    this.about,
    this.nip05,
    this.lud16,
    this.lud06,
  }) {
    if (this.event != null) {
      this.pubkey = this.event!.pubkey;
    } else {
      this.pubkey = pubkey!;
    }
  }

  Metadata.blank(this.pubkey);

  Metadata.fromEvent(final Event event) {
    // ignore: prefer_initializing_formals
    this.event = event;
    this.pubkey = event.pubkey;

    try {
      final json = jsonDecode(event.content);
      this.name = json["name"];
      this.displayName = json["display_name"];
      this.picture = json["picture"];
      this.banner = json["banner"];
      this.website = json["website"];
      this.about = json["about"];
      this.nip05 = json["nip05"];
      this.lud16 = json["lud16"];
      this.lud06 = json["lud06"];
    } catch (err) {
      /***/
    }
  }

  @override
  Event? event;

  @override
  late String pubkey;

  @override
  int? storedAt;

  String? name;
  String? displayName;
  String? picture;
  String? banner;
  String? website;
  String? about;
  String? nip05;
  String? lud16;
  String? lud06;

  bool? nip05valid;
  bool isBlank() {
    return this.event == null;
  }

  Future<Event> toEvent(final SignerFunction signer) async {
    final Map<String, dynamic> data = <String, dynamic>{};
    data["name"] = name;
    data["display_name"] = displayName;
    data["picture"] = picture;
    data["banner"] = banner;
    data["website"] = website;
    data["about"] = about;
    data["nip05"] = nip05;
    data["lud16"] = lud16;
    data["lud06"] = lud06;
    final event =
        await Event.finalizeWithSigner(signer, 0, [], jsonEncode(data));
    this.event = event;
    return event;
  }

  Future<bool> validateNIP05() async {
    if (this.nip05valid != null) return this.nip05valid!;
    if (this.nip05 == null) return false;

    final pp = await NIP05.search(this.nip05!);
    if (pp == null) {
      this.nip05valid = false;
      return false;
    }

    this.nip05valid = pp.pubkey == this.nip05!;
    return this.nip05valid!;
  }
}
