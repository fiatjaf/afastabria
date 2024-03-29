import "dart:convert";
import "package:crypto/crypto.dart";
import "package:clock/clock.dart";
import "package:bip340/bip340.dart" as schnorr;

import "package:loure/client/client_utils/keys.dart";
import "package:loure/client/filter.dart";

class Finalized {
  Finalized(this.id, this.pubkey, this.sig);
  String id;
  String pubkey;
  String sig;
}

typedef SignerFunction = Future<Finalized> Function(
    int, int, List<List<String>>, String);
typedef Tag = List<String>;
typedef Tags = List<Tag>;

class Event {
  Event(this.id, this.pubkey, this.createdAt, this.kind, this.tags,
      this.content, this.sig);

  factory Event.finalize(final String privateKey, int kind,
      List<List<String>> tags, String content,
      {final DateTime? publishAt}) {
    final createdAt = publishAt != null
        ? publishAt.millisecondsSinceEpoch ~/ 1000
        : clock.now().millisecondsSinceEpoch ~/ 1000;

    final fin = Event.sign(privateKey, createdAt, kind, tags, content);
    return Event(fin.id, fin.pubkey, createdAt, kind, tags, content, fin.sig);
  }

  factory Event.fromJson(final Map<String, dynamic> data) {
    final id = data["id"] as String;
    final pubkey = data["pubkey"] as String;
    final createdAt = data["created_at"] as int;
    final kind = data["kind"] as int;
    final content = data["content"] as String;
    final tags = (data["tags"] as List<dynamic>)
        .map((final tagDyn) => (tagDyn as List<dynamic>)
            .map((final itemDyn) => itemDyn as String)
            .toList())
        .toList();
    final sig = data["sig"] as String;

    return Event(id, pubkey, createdAt, kind, tags, content, sig);
  }

  late final String id;
  late final String pubkey;
  late final String sig;

  late final int createdAt;

  final int kind;
  final Tags tags;
  final String content;

  Set<String> sources = {};

  static Future<Event> finalizeWithSigner(final SignerFunction sign, int kind,
      List<List<String>> tags, String content,
      {final DateTime? publishAt}) async {
    final createdAt = publishAt != null
        ? publishAt.millisecondsSinceEpoch ~/ 1000
        : clock.now().millisecondsSinceEpoch ~/ 1000;

    final fin = await sign(createdAt, kind, tags, content);
    return Event(fin.id, fin.pubkey, createdAt, kind, tags, content, fin.sig);
  }

  Tag? getTag(final String name) {
    for (final tag in this.tags) {
      if (tag.length >= 2 && tag[0] == name) return tag;
    }
    return null;
  }

  List<String> getTagValues(final String name) {
    final List<String> result = [];
    for (final tag in this.tags) {
      if (tag.length >= 2 && tag[0] == name) {
        result.add(tag[1]);
      }
    }
    return result;
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "pubkey": pubkey,
      "created_at": createdAt,
      "kind": kind,
      "tags": tags,
      "content": content,
      "sig": sig
    };
  }

  bool get isValid {
    if (this.id !=
        getId(
            this.pubkey, this.createdAt, this.kind, this.tags, this.content)) {
      return false;
    }
    if (!schnorr.verify(this.pubkey, this.id, this.sig)) {
      return false;
    }
    return true;
  }

  // Individual events with the same "id" are equivalent
  @override
  bool operator ==(final other) => other is Event && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return jsonEncode(this.toJson());
  }

  bool matches(final Filter filter) {
    if (filter.authors != null &&
        !filter.authors!.any((final o) => this.pubkey == o)) {
      return false;
    }
    if (filter.ids != null && !filter.ids!.any((final o) => this.id == o)) {
      return false;
    }
    if (filter.kinds != null &&
        !filter.kinds!.any((final o) => this.kind == o)) {
      return false;
    }
    if (filter.e != null &&
        !filter.e!.any((final o) => this.getTagValues("e").contains(o))) {
      return false;
    }
    if (filter.a != null &&
        !filter.a!.any((final o) => this.getTagValues("a").contains(o))) {
      return false;
    }
    if (filter.p != null &&
        !filter.p!.any((final o) => this.getTagValues("p").contains(o))) {
      return false;
    }
    if (filter.t != null &&
        !filter.t!.any((final o) => this.getTagValues("t").contains(o))) {
      return false;
    }
    if (filter.d != null &&
        !filter.d!.any((final o) => this.getTagValues("d").contains(o))) {
      return false;
    }

    return true;
  }

  static String getId(
      String pubkey, int createdAt, int kind, Tags tags, String content) {
    final jsonData =
        '[0,"$pubkey",$createdAt,$kind,${json.encode(tags)},${json.encode(content)}]';
    final bytes = utf8.encode(jsonData);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  static Finalized sign(
      String privateKey, int createdAt, int kind, Tags tags, String content) {
    final pubkey = getPublicKey(privateKey);
    final id = getId(pubkey, createdAt, kind, tags, content);
    final aux = getRandomHexString();
    final sig = schnorr.sign(privateKey, id, aux);
    return Finalized(id, pubkey, sig);
  }

  static SignerFunction getSigner(String privateKey) {
    return (int createdAt, int kind, Tags tags, String content) async {
      return Event.sign(privateKey, createdAt, kind, tags, content);
    };
  }
}
