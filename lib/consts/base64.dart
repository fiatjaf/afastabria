import "dart:convert";
import "dart:typed_data";

class BASE64 {
  static const String PREFIX = "data:image/png;base64,";

  static bool check(final String str) {
    return str.indexOf(PREFIX) == 0;
  }

  static Uint8List toData(final String base64Str) {
    return const Base64Decoder().convert(base64Str.replaceFirst(PREFIX, ""));
  }

  static String toBase64(final Uint8List data) {
    final base64Str = base64Encode(data);
    return "${BASE64.PREFIX}$base64Str";
  }
}
