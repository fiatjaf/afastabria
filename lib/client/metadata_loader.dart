import "package:graphql_data_loader2/graphql_data_loader2.dart";

import "package:loure/client/event.dart";
import "package:loure/client/filter.dart";
import "package:loure/data/metadata.dart";
import "package:loure/data/metadata_db.dart";
import "package:loure/main.dart";

class MetadataLoader {
  final DataLoader<String, Metadata> _loader =
      DataLoader(batchLoad, cache: false);

  final Map<String, Future<Metadata>> _promises = {};

  static Future<List<Metadata>> batchLoad(final Iterable<String> keys) async {
    final threshold = DateTime.now()
            .subtract(const Duration(days: 3))
            .millisecondsSinceEpoch /
        1000;

    final events = await pool.querySync(
        nostr.METADATA_RELAYS, Filter(kinds: [0], authors: keys.toList()));

    return await Future.wait(
      keys.map((final String key) async {
        final fromDB = await MetadataDB.get(key);
        if (fromDB != null && fromDB.event!.createdAt > threshold) {
          return fromDB;
        }

        try {
          final md = Metadata.fromEvent(
              events.firstWhere((final Event event) => event.pubKey == key));

          if (fromDB == null) {
            MetadataDB.insert(md);
          } else if (md.event!.createdAt > fromDB.event!.createdAt) {
            MetadataDB.update(md);
          }
          return md;
        } catch (err) {
          return Metadata.blank(key);
        }
      }),
    );
  }

  Future<Metadata> load(final String pubkey) {
    return this._promises.putIfAbsent(pubkey, () => this._loader.load(pubkey));
  }

  void invalidate(final String pubkey) {
    MetadataDB.delete(pubkey);
    this._promises.remove(pubkey);
  }

  void clear() {
    this._loader.close();
    MetadataDB.deleteAll();
  }
}
