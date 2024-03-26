import "dart:convert";
import "dart:typed_data";

import "package:bech32/bech32.dart" as bech32;
import "package:hex/hex.dart";

import "package:loure/client/input.dart";
import "package:loure/component/content/content_decoder.dart";

final b32decoder = bech32.Bech32Decoder();
final b32encoder = bech32.Bech32Encoder();

class NIP19 {
  static bool isPubkey(final String str) => str.startsWith("npub1");
  static bool isPrivateKey(final String str) => str.startsWith("nsec1");
  static bool isNprofile(final String text) => text.startsWith("nprofile1");
  static bool isNoteId(final String str) => str.startsWith("note1");
  static bool isNevent(final String text) => text.startsWith("nevent1");
  static bool isNaddr(final String text) => text.startsWith("naddr1");

  static String encodePubKey(final String pubkey) {
    return _encodeKey("npub", pubkey);
  }

  static String encodeSimplePubKey(final String pubkey) {
    final code = encodePubKey(pubkey);
    final length = code.length;
    return "${code.substring(0, 6)}:${code.substring(length - 6)}";
  }

  static String decode(final String npub) {
    try {
      final bech32Result = b32decoder.convert(npub);
      final data = convertBits(bech32Result.data, 5, 8, false);
      return HEX.encode(data);
    } catch (e) {
      print("NIP19 decode error ${e.toString()}");
      return "";
    }
  }

  static String _encodeKey(final String hrp, final String key) {
    var data = HEX.decode(key);
    data = convertBits(data, 8, 5, true);

    final input = bech32.Bech32(hrp, data);
    return b32encoder.convert(input);
  }

  static String encodePrivateKey(final String pubkey) {
    return _encodeKey("nsec", pubkey);
  }

  static String encodeNoteId(final String id) {
    return _encodeKey("note", id);
  }

  static Uint8List? _decodePreHandle(String text) {
    try {
      text = text.replaceAll(ContentDecoder.NOTE_REFERENCES, "");

      final bech32Result = b32decoder.convert(text, 10000);
      final buf =
          Uint8List.fromList(convertBits(bech32Result.data, 5, 8, false));

      return buf;
    } catch (e) {
      return null;
    }
  }

  static ProfilePointer? decodeNprofile(final String text) {
    final buf = _decodePreHandle(text);
    if (buf == null) return null;

    String? pubkey;
    List<String> relays = [];

    int startIndex = 0;
    while (true) {
      final tlvData = TLVUtil.readTLVEntry(buf, startIndex: startIndex);
      if (tlvData == null) {
        break;
      }
      startIndex += tlvData.length + 2;

      if (tlvData.typ == TLVType.Default) {
        pubkey = HEX.encode(tlvData.data);
      } else if (tlvData.typ == TLVType.Relay) {
        final relay = utf8.decode(tlvData.data);
        relays.add(relay);
      }
    }

    if (pubkey != null) {
      return ProfilePointer(pubkey, relays);
    }

    return null;
  }

  static EventPointer? decodeNevent(final String text) {
    final buf = _decodePreHandle(text);
    if (buf == null) return null;

    String? id;
    List<String> relays = [];
    String? author;
    int? kind;

    int startIndex = 0;
    while (true) {
      final tlvData = TLVUtil.readTLVEntry(buf, startIndex: startIndex);
      if (tlvData == null) {
        break;
      }
      startIndex += tlvData.length + 2;

      if (tlvData.typ == TLVType.Default) {
        id = HEX.encode(tlvData.data);
      } else if (tlvData.typ == TLVType.Relay) {
        final relay = utf8.decode(tlvData.data);
        relays.add(relay);
      } else if (tlvData.typ == TLVType.Author) {
        author = HEX.encode(tlvData.data);
      } else if (tlvData.typ == TLVType.Kind) {
        kind = ByteData.view(tlvData.data.buffer).getUint32(0, Endian.big);
      }
    }

    if (id != null) {
      return EventPointer(id, relays, author, kind);
    }

    return null;
  }

  static AddressPointer? decodeNaddr(final String text) {
    final buf = _decodePreHandle(text);
    if (buf == null) return null;

    String? id;
    String? author;
    int? kind;
    final List<String> relays = [];

    int startIndex = 0;
    while (true) {
      final tlvData = TLVUtil.readTLVEntry(buf, startIndex: startIndex);
      if (tlvData == null) {
        break;
      }
      startIndex += tlvData.length + 2;

      if (tlvData.typ == TLVType.Default) {
        id = HEX.encode(tlvData.data);
      } else if (tlvData.typ == TLVType.Relay) {
        final relay = utf8.decode(tlvData.data);
        relays.add(relay);
      } else if (tlvData.typ == TLVType.Kind) {
        kind = ByteData.view(tlvData.data.buffer).getUint32(0, Endian.big);
      } else if (tlvData.typ == TLVType.Author) {
        author = HEX.encode(tlvData.data);
      }
    }

    if (id != null && author != null && kind != null) {
      return AddressPointer(id, author, kind, relays);
    }

    return null;
  }

  static String _handleEncodeResult(final String hrp, final List<int> buf) {
    final input = bech32.Bech32(hrp, buf);
    return ContentDecoder.NOTE_REFERENCES + b32encoder.convert(input, 2000);
  }

  static String encodeNprofile(final ProfilePointer o) {
    List<int> buf = [];
    TLVUtil.writeTLVEntry(buf, TLVType.Default, HEX.decode(o.pubkey));
    for (final relay in o.relays) {
      TLVUtil.writeTLVEntry(buf, TLVType.Relay, utf8.encode(relay));
    }

    buf = convertBits(buf, 8, 5, true);
    return _handleEncodeResult("nprofile", buf);
  }

  static String encodeNevent(final EventPointer o) {
    List<int> buf = [];
    TLVUtil.writeTLVEntry(buf, TLVType.Default, HEX.decode(o.id));
    for (final relay in o.relays) {
      TLVUtil.writeTLVEntry(buf, TLVType.Relay, utf8.encode(relay));
    }
    if (o.author != null) {
      TLVUtil.writeTLVEntry(buf, TLVType.Author, utf8.encode(o.author!));
    }

    buf = convertBits(buf, 8, 5, true);
    return _handleEncodeResult("nevent", buf);
  }

  static String encodeNaddr(final AddressPointer o) {
    List<int> buf = [];
    TLVUtil.writeTLVEntry(buf, TLVType.Default, HEX.decode(o.identifier));
    TLVUtil.writeTLVEntry(buf, TLVType.Author, HEX.decode(o.pubkey));
    TLVUtil.writeTLVEntry(buf, TLVType.Kind, [o.kind]);
    for (final relay in o.relays) {
      TLVUtil.writeTLVEntry(buf, TLVType.Relay, utf8.encode(relay));
    }

    buf = convertBits(buf, 8, 5, true);
    return _handleEncodeResult("naddr", buf);
  }
}

class TLVUtil {
  static TLVData? readTLVEntry(
    final Uint8List data, {
    final int startIndex = 0,
  }) {
    final dataLength = data.length;
    if (dataLength < startIndex + 2) {
      return null;
    }

    final typ = data[startIndex];
    final length = data[startIndex + 1];

    if (dataLength >= startIndex + 2 + length) {
      final value =
          Uint8List.sublistView(data, startIndex + 2, startIndex + 2 + length);
      return TLVData(typ, length, value);
    }

    return null;
  }

  static writeTLVEntry(
      final List<int> buf, final int typ, final List<int> data) {
    final length = data.length;
    buf.add(typ);
    buf.add(length);
    buf.addAll(data);
  }
}

class TLVData {
  TLVData(this.typ, this.length, this.data);

  int typ;
  int length;
  Uint8List data;
}

class TLVType {
  static const int Default = 0;
  static const int Relay = 1;
  static const int Author = 2;
  static const int Kind = 3;
}

List<int> convertBits(
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
    throw bech32.InvalidPadding("illegal zero padding");
  } else if (((acc << (to - bits)) & maxv) != 0) {
    throw bech32.InvalidPadding("non zero");
  }

  return result;
}
