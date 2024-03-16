import "dart:convert";
import "package:crypto/crypto.dart";
import "package:clock/clock.dart";
import "package:bip340/bip340.dart" as schnorr;
import "package:hex/hex.dart";

import "package:loure/client/client_utils/keys.dart";

/// A Nostr event
class Event {
  Event(this.id, this.pubKey, this.createdAt, this.kind, this.tags,
      this.content, this.sig);

  Event.finalize(final String privateKey, this.kind, this.tags, this.content,
      {final DateTime? publishAt, final int proofOfWorkDifficulty = 0}) {
    if (publishAt != null) {
      createdAt = publishAt.millisecondsSinceEpoch ~/ 1000;
    } else {
      createdAt = _secondsSinceEpoch();
    }

    if (proofOfWorkDifficulty > 0) {
      final difficultyInBytes = (proofOfWorkDifficulty / 8).ceil();
      this.tags.add(["nonce", "0", proofOfWorkDifficulty.toString()]);
      int nonce = 0;
      do {
        const int nonceIndex = 1;
        this.tags.last[nonceIndex] = (++nonce).toString();
        this.id = this.getId();
      } while (_countLeadingZeroBytes(this.id) < difficultyInBytes);
    }

    this.sign(privateKey);
  }

  factory Event.fromJson(final Map<String, dynamic> data) {
    final id = data["id"] as String;
    final pubKey = data["pubkey"] as String;
    final createdAt = data["created_at"] as int;
    final kind = data["kind"] as int;
    final content = data["content"] as String;
    final tags = (data["tags"] as List<dynamic>)
        .map((final tagDyn) => (tagDyn as List<dynamic>)
            .map((final itemDyn) => itemDyn as String)
            .toList())
        .toList();
    final sig = data["sig"] as String;

    return Event(id, pubKey, createdAt, kind, tags, content, sig);
  }
  late String id;
  late String pubKey;
  late String sig;

  late int createdAt;
  final int kind;

  final List<List<String>> tags;
  final String content;

  Set<String> sources = {};

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "pubkey": pubKey,
      "created_at": createdAt,
      "kind": kind,
      "tags": tags,
      "content": content,
      "sig": sig
    };
  }

  void sign(final String privateKey) {
    this.pubKey = getPublicKey(privateKey);
    this.id = this.getId();
    final aux = getRandomHexString();
    this.sig = schnorr.sign(privateKey, this.id, aux);
  }

  bool get isValid {
    if (this.id != getId()) {
      return false;
    }
    if (!schnorr.verify(this.pubKey, this.id, this.sig)) {
      return false;
    }
    return true;
  }

  String getId() {
    final jsonData = json.encode(
        [0, this.pubKey, this.createdAt, this.kind, this.tags, this.content]);
    final bytes = utf8.encode(jsonData);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Individual events with the same "id" are equivalent
  @override
  bool operator ==(final other) => other is Event && id == other.id;
  @override
  int get hashCode => id.hashCode;

  static int _secondsSinceEpoch() {
    final now = clock.now();
    final secondsSinceEpoch = now.millisecondsSinceEpoch ~/ 1000;
    return secondsSinceEpoch;
  }

  int _countLeadingZeroBytes(final String eventId) {
    List<int> bytes = HEX.decode(eventId);
    int zeros = 0;
    for (int i = 0; i < bytes.length; i++) {
      if (bytes[i] == 0) {
        zeros = i + 1;
      } else {
        break;
      }
    }
    return zeros;
  }
}
