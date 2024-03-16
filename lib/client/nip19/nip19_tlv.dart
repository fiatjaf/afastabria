import "dart:convert";

import "package:bech32/bech32.dart";
import "package:hex/hex.dart";

import "package:loure/client/nip19/nip19.dart";
import "package:loure/client/nip19/tlv_util.dart";
import "package:loure/component/content/content_decoder.dart";

class NIP19Tlv {
  static bool isNprofile(final String text) {
    return Nip19.isKey(Hrps.NPROFILE, text);
  }

  static bool isNevent(final String text) {
    return Nip19.isKey(Hrps.NEVENT, text);
  }

  static bool isNrelay(final String text) {
    return Nip19.isKey(Hrps.NRELAY, text);
  }

  static bool isNaddr(final String text) {
    return Nip19.isKey(Hrps.NADDR, text);
  }

  static List<int> _decodePreHandle(String text) {
    try {
      text = text.replaceAll(ContentDecoder.NOTE_REFERENCES, "");

      final decoder = Bech32Decoder();
      final bech32Result = decoder.convert(text, 1000);
      final buf = Nip19.convertBits(bech32Result.data, 5, 8, false);

      return buf;
    } catch (e) {
      return [];
    }
  }

  static Nprofile? decodeNprofile(final String text) {
    List<int> buf = _decodePreHandle(text);

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
      return Nprofile(pubkey: pubkey, relays: relays);
    }

    return null;
  }

  static Nevent? decodeNevent(final String text) {
    List<int> buf = _decodePreHandle(text);

    String? id;
    List<String> relays = [];
    String? author;

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
      }
    }

    if (id != null) {
      return Nevent(id: id, relays: relays, author: author);
    }

    return null;
  }

  static Nrelay? decodeNrelay(final String text) {
    List<int> buf = _decodePreHandle(text);

    String? addr;

    int startIndex = 0;
    while (true) {
      final tlvData = TLVUtil.readTLVEntry(buf, startIndex: startIndex);
      if (tlvData == null) {
        break;
      }
      startIndex += tlvData.length + 2;

      if (tlvData.typ == TLVType.Default) {
        final relay = utf8.decode(tlvData.data);
        addr = relay;
      }
    }

    if (addr != null) {
      return Nrelay(addr);
    }

    return null;
  }

  static Naddr? decodeNaddr(final String text) {
    List<int> buf = _decodePreHandle(text);

    String? id;
    String? author;
    int? kind;
    List<String> relays = [];

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
        kind = tlvData.data[0];
      } else if (tlvData.typ == TLVType.Author) {
        author = HEX.encode(tlvData.data);
      }
    }

    if (id != null && author != null && kind != null) {
      return Naddr(id: id, author: author, kind: kind, relays: relays);
    }

    return null;
  }

  static String _handleEncodeResult(final String hrp, final List<int> buf) {
    final encoder = Bech32Encoder();
    final Bech32 input = Bech32(hrp, buf);
    return ContentDecoder.NOTE_REFERENCES + encoder.convert(input, 2000);
  }

  static String encodeNprofile(final Nprofile o) {
    List<int> buf = [];
    TLVUtil.writeTLVEntry(buf, TLVType.Default, HEX.decode(o.pubkey));
    if (o.relays != null) {
      for (final relay in o.relays!) {
        TLVUtil.writeTLVEntry(buf, TLVType.Relay, utf8.encode(relay));
      }
    }

    buf = Nip19.convertBits(buf, 8, 5, true);

    return _handleEncodeResult(Hrps.NPROFILE, buf);
  }

  static String encodeNevent(final Nevent o) {
    List<int> buf = [];
    TLVUtil.writeTLVEntry(buf, TLVType.Default, HEX.decode(o.id));
    if (o.relays != null) {
      for (final relay in o.relays!) {
        TLVUtil.writeTLVEntry(buf, TLVType.Relay, utf8.encode(relay));
      }
    }
    if (o.author != null) {
      TLVUtil.writeTLVEntry(buf, TLVType.Author, utf8.encode(o.author!));
    }

    buf = Nip19.convertBits(buf, 8, 5, true);

    return _handleEncodeResult(Hrps.NEVENT, buf);
  }

  static String encodeNrelay(final Nrelay o) {
    List<int> buf = [];
    TLVUtil.writeTLVEntry(buf, TLVType.Default, utf8.encode(o.addr));

    buf = Nip19.convertBits(buf, 8, 5, true);

    return _handleEncodeResult(Hrps.NRELAY, buf);
  }

  static String encodeNaddr(final Naddr o) {
    List<int> buf = [];
    TLVUtil.writeTLVEntry(buf, TLVType.Default, HEX.decode(o.id));
    TLVUtil.writeTLVEntry(buf, TLVType.Author, HEX.decode(o.author));
    TLVUtil.writeTLVEntry(buf, TLVType.Kind, [o.kind]);
    if (o.relays != null) {
      for (final relay in o.relays!) {
        TLVUtil.writeTLVEntry(buf, TLVType.Relay, utf8.encode(relay));
      }
    }

    buf = Nip19.convertBits(buf, 8, 5, true);

    return _handleEncodeResult(Hrps.NRELAY, buf);
  }
}

class Nprofile {
  Nprofile({required this.pubkey, this.relays});
  String pubkey;
  Iterable<String>? relays;
}

class Nevent {
  Nevent({required this.id, this.relays, this.author});
  String id;
  Iterable<String>? relays;
  String? author;
}

class Nrelay {
  Nrelay(this.addr);
  String addr;
}

class Naddr {
  Naddr({
    required this.id,
    required this.author,
    required this.kind,
    this.relays,
  });
  String id;
  String author;
  int kind;
  Iterable<String>? relays;
}
