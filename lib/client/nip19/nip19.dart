import "package:bech32/bech32.dart";
import "package:hex/hex.dart";

class Hrps {
  static const String PUBLIC_KEY = "npub";
  static const String PRIVATE_KEY = "nsec";
  static const String NOTE_ID = "note";
  static const String NPROFILE = "nprofile";
  static const String NEVENT = "nevent";
  static const String NRELAY = "nrelay";
  static const String NADDR = "naddr";
}

class Nip19 {
  // static String encodePubKey(String pubkey) {
  //   var data = hex.decode(pubkey);
  //   data = Bech32.convertBits(data, 8, 5, true);
  //   return Bech32.encode(Hrps.PUBLIC_KEY, data);
  // }

  static bool isKey(final String hrp, final String str) {
    if (str.indexOf(hrp) == 0) {
      return true;
    } else {
      return false;
    }
  }

  static bool isPubkey(final String str) {
    return isKey(Hrps.PUBLIC_KEY, str);
  }

  static String encodePubKey(final String pubkey) {
    // var data = HEX.decode(pubkey);
    // data = _convertBits(data, 8, 5, true);

    // var encoder = Bech32Encoder();
    // Bech32 input = Bech32(Hrps.PUBLIC_KEY, data);
    // return encoder.convert(input);
    return _encodeKey(Hrps.PUBLIC_KEY, pubkey);
  }

  static String encodeSimplePubKey(final String pubkey) {
    final code = encodePubKey(pubkey);
    final length = code.length;
    return "${code.substring(0, 6)}:${code.substring(length - 6)}";
  }

  // static String decode(String npub) {
  //   var res = Bech32.decode(npub);
  //   var data = Bech32.convertBits(res.words, 5, 8, false);
  //   return hex.encode(data).substring(0, 64);
  // }
  static String decode(final String npub) {
    try {
      final decoder = Bech32Decoder();
      final bech32Result = decoder.convert(npub);
      final data = convertBits(bech32Result.data, 5, 8, false);
      return HEX.encode(data);
    } catch (e) {
      print("Nip19 decode error ${e.toString()}");
      return "";
    }
  }

  static String _encodeKey(final String hrp, final String key) {
    var data = HEX.decode(key);
    data = convertBits(data, 8, 5, true);

    final encoder = Bech32Encoder();
    final Bech32 input = Bech32(hrp, data);
    return encoder.convert(input);
  }

  static bool isPrivateKey(final String str) {
    return isKey(Hrps.PRIVATE_KEY, str);
  }

  static String encodePrivateKey(final String pubkey) {
    return _encodeKey(Hrps.PRIVATE_KEY, pubkey);
  }

  static bool isNoteId(final String str) {
    return isKey(Hrps.NOTE_ID, str);
  }

  static String encodeNoteId(final String id) {
    return _encodeKey(Hrps.NOTE_ID, id);
  }

  static List<int> convertBits(
      final List<int> data, final int from, final int to, final bool pad) {
    var acc = 0;
    var bits = 0;
    final result = <int>[];
    final maxv = (1 << to) - 1;

    for (final v in data) {
      if (v < 0 || (v >> from) != 0) {
        throw Exception();
      }
      acc = (acc << from) | v;
      bits += from;
      while (bits >= to) {
        bits -= to;
        result.add((acc >> bits) & maxv);
      }
    }

    if (pad) {
      if (bits > 0) {
        result.add((acc << (to - bits)) & maxv);
      }
    } else if (bits >= from) {
      throw InvalidPadding("illegal zero padding");
    } else if (((acc << (to - bits)) & maxv) != 0) {
      throw InvalidPadding("non zero");
    }

    return result;
  }
}
