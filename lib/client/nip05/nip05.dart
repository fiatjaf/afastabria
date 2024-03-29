import "dart:convert";

import "package:http/http.dart" as http;

import "package:loure/client/input.dart";

class NIP05 {
  static final REGEX = RegExp(r"^(?:([\w.+-]+)@)?([\w_-]+(\.[\w_-]+)+)$");

  static bool isNIP05(String text) => REGEX.hasMatch(text);

  static Future<ProfilePointer?> search(String nip05) async {
    var name = "_";
    var host = nip05;
    final spl = host.split("@");
    if (spl.length > 1) {
      name = spl[0];
      host = spl[1];
    }

    final url = "https://$host/.well-known/nostr.json?name=$name";

    try {
      final response = await http.get(Uri.parse(url));
      final res = jsonDecode(response.body) as Map;
      final pubkey = res["names"][name] as String;
      List<String> relays = [];
      try {
        final allRelays = res["relays"] as Map;
        relays =
            (allRelays[pubkey] as List).map((final r) => r as String).toList();
      } catch (err) {/***/}
      return ProfilePointer(pubkey, relays);
    } catch (err) {
      return null;
    }
  }
}
