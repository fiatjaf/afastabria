import "dart:convert";
import "package:convert/convert.dart";
import "package:crypto/crypto.dart" as crypto;

class HashUtil {
  static String md5(final String source) {
    final content = const Utf8Encoder().convert(source);
    final digest = crypto.md5.convert(content);
    // digest.toString()
    return hex.encode(digest.bytes);
  }

  static String sha1Bytes(final List<int> content) {
    final digest = crypto.sha1.convert(content);
    return hex.encode(digest.bytes);
  }
}
