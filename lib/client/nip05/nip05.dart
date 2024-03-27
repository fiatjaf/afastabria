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
      final String pubkey = res["names"][name];
      final Map<String, List<String>> relays = res["relays"] ?? {};
      return ProfilePointer(pubkey, relays[pubkey] ?? []);
    } catch (e) {
      return null;
    }
  }
}
