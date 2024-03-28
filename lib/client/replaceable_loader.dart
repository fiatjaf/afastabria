import "dart:convert";

import "package:graphql_data_loader2/graphql_data_loader2.dart";

import "package:loure/client/event.dart";
import "package:loure/client/filter.dart";
import "package:loure/data/replaceable_db.dart";
import "package:loure/main.dart";

abstract class Replaceable {
  String get pubkey;
  Event? get event;
  int? get storedAt;
  set storedAt(int? _);
}

class ReplaceableLoader<K extends Replaceable> {
  ReplaceableLoader({
    required String dbname,
    required this.read,
    required this.blank,
    required Duration thresholdDelta,
    required this.baseRelays,
    required this.kind,
    required this.queryId,
    final K Function(String)? deflt,
  }) {
    this._loader = DataLoader(this.batchLoad, cache: false);
    this.db = ReplaceableDB(dbname, (final row) {
      final thing =
          this.read(Event.fromJson(jsonDecode(row["event"] as String)));
      thing.storedAt = row["stored_at"] as int;
      return thing;
    });
    this.threshold =
        DateTime.now().subtract(thresholdDelta).millisecondsSinceEpoch ~/ 1000;
    this.deflt = deflt ?? this.blank;
  }

  final K Function(Event) read; // initialize an instance from an event

  // initialize a blank instance with just a pubkey
  final K Function(String) blank;
  final List<String> baseRelays;
  final int kind;
  final String queryId; // for debugging purposes

  // initialize a blank instance, but prefilled
  late final K Function(String) deflt;

  // how long until we deem a record in the database old enough and try to fetch a new
  late final int threshold;
  late final ReplaceableDB<K> db;
  late final DataLoader<String, K> _loader;

  final Map<String, Future<K>> _promises = {};

  Future<void> save(final K rt) async {
    await this.db.upsert(rt);
    this.invalidate(rt.pubkey);
  }

  Future<List<K>> batchLoad(final Iterable<String> keys) async {
    final results = keys.map(blank).toList();
    final remaining = keys.toSet();

    // try to batch load keys from the database
    final dbResults = await this.db.batchGet(keys);
    for (final md in dbResults) {
      for (var i = 0; i < results.length; i++) {
        if (md.pubkey == results[i].pubkey) {
          // assign obtained results to their proper place in the results array
          results[i] = md;

          // remove this key so we don't query relays for it
          // but only if the version we have locally is recent enough
          if (md.storedAt! > threshold) {
            remaining.remove(md.pubkey);
          }
        }
      }
    }

    // try the relays with the remaining
    if (remaining.length > 0) {
      final events = await pool.querySync(
        this.baseRelays,
        Filter(kinds: [this.kind], authors: remaining.toList()),
        id: this.queryId,
      );

      for (final mde in events) {
        for (var i = 0; i < results.length; i++) {
          if (mde.pubkey == results[i].pubkey) {
            final md = this.read(mde);
            results[i] = md;
            this.db.upsert(md);
          }
        }
      }
    }

    return results;
  }

  Future<K> load(final String pubkey) {
    return this._promises.putIfAbsent(pubkey, () => this._loader.load(pubkey));
  }

  void invalidate(final String pubkey) {
    this.db.delete(pubkey);
    this._promises.remove(pubkey);
  }
}
