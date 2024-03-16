import "package:encrypt/encrypt.dart";

class EncryptUtil {
  // AES128 CBC pkcs7padding iv util8 base64
  static String aesEncrypt(
      final String plainText, final String keyStr, final String ivStr) {
    final key = Key.fromUtf8(keyStr);
    final iv = IV.fromUtf8(ivStr);

    final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
    final encrypted = encrypter.encrypt(plainText, iv: iv);

    return encrypted.base64;
  }

  static String aesEncryptBytes(
      final List<int> input, final String keyStr, final String ivStr) {
    final key = Key.fromUtf8(keyStr);
    final iv = IV.fromUtf8(ivStr);

    final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
    final encrypted = encrypter.encryptBytes(input, iv: iv);

    return encrypted.base64;
  }

  static String aesDecrypt(
      final String str, final String keyStr, final String ivStr) {
    final key = Key.fromUtf8(keyStr);
    final iv = IV.fromUtf8(ivStr);

    final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
    final decrypted = encrypter.decrypt64(str, iv: iv);

    return decrypted;
  }
}
