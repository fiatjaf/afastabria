import "package:bech32/bech32.dart";

class ZapCoder {
  static Bech32 decode(final String text) {
    final decoder = Bech32Decoder();
    final bech32Result = decoder.convert(text, 1000);
    return bech32Result;
  }
}
