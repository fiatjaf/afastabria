import "dart:math";

import "package:bip340/bip340.dart" as schnorr;
import "package:hex/hex.dart";
import "package:string_validator/string_validator.dart";

/// Generates a random new secret key which is a 32-byte hexadecimal string.
String generatePrivateKey() => getRandomHexString();

/// Returns the BIP340 public key derived from [privateKey].
///
/// An [ArgumentError] is thrown if [privateKey] is invalid.
String getPublicKey(final String privateKey) {
  return schnorr.getPublicKey(privateKey);
}

/// Whether [key] is a a 32-byte hexadecimal string.
bool keyIsValid(final String key) {
  return isHexadecimal(key) && key.length == 64;
}

String getRandomHexString([final int byteLength = 32]) {
  final Random random = Random.secure();
  final bytes =
      List<int>.generate(byteLength, (final i) => random.nextInt(256));
  return HEX.encode(bytes);
}
