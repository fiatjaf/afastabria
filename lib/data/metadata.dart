import "dart:convert";

import "package:http/http.dart" as http;

import "package:loure/client/event.dart";

class Metadata {
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
      this.pubkey = this.event!.pubKey;
    } else {
      this.pubkey = pubkey!;
    }
  }

  Metadata.blank(this.pubkey);

  Metadata.fromEvent(final Event event) {
    // ignore: prefer_initializing_formals
    this.event = event;
    this.pubkey = event.pubKey;

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
  late Event? event;
  late String pubkey;

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

  Map<String, dynamic> toJson() {
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
    return data;
  }

  Future<bool> valid() async {
    if (this.nip05valid != null) return this.nip05valid!;
    if (this.nip05 == null) return false;

    var name = "_";
    var host = this.nip05!;
    final spl = host.split("@");
    if (spl.length > 1) {
      name = spl[0];
      host = spl[1];
    }

    final url = "https://$host/.well-known/nostr.json?name=$name";

    try {
      final response = await http.get(Uri.parse(url));
      final res = jsonDecode(response.body) as Map;
      return res["names"][name] == this.pubkey;
    } catch (e) {
      return false;
    }
  }
}
