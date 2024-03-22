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

  final threshold =
      DateTime.now().subtract(const Duration(days: 3)).millisecondsSinceEpoch /
          1000;

  static Future<List<Metadata>> batchLoad(final Iterable<String> keys) async {
    final events = await pool.querySync(
        nostr.METADATA_RELAYS, Filter(kinds: [0], authors: keys.toList()));

    return await Future.wait(
      keys.map((final String key) async {
        try {
          final md = Metadata.fromEvent(
              events.firstWhere((final Event event) => event.pubkey == key));

          MetadataDB.upsert(md);
          return md;
        } catch (err) {
          return Metadata.blank(key);
        }
      }),
    );
  }

  Future<Metadata> load(final String pubkey) {
    return this._promises.putIfAbsent(pubkey, () {
      return MetadataDB.get(pubkey).then((Metadata? md) {
        if (md != null && md.event!.createdAt > threshold) {
          return md;
        }
        return this._loader.load(pubkey);
      });
    });
  }

  void invalidate(final String pubkey) {
    MetadataDB.delete(pubkey);
    this._promises.remove(pubkey);
  }
}
