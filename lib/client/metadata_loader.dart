import 'package:graphql_data_loader2/graphql_data_loader2.dart';

import 'package:loure/client/event.dart';
import 'package:loure/client/filter.dart';
import 'package:loure/data/metadata.dart';
import 'package:loure/data/metadata_db.dart';
import 'package:loure/main.dart';

class MetadataLoader {
  DataLoader<String, Metadata> loader = DataLoader(batchLoad);

  static Future<List<Metadata>> batchLoad(Iterable<String> keys) async {
    final threshold = DateTime.now()
            .subtract(const Duration(days: 3))
            .millisecondsSinceEpoch /
        1000;

    final events = await nostr.pool.querySync(
        nostr.METADATA_RELAYS, Filter(kinds: [0], authors: keys.toList()));

    return await Future.wait(
      keys.map((String key) async {
        final fromDB = await MetadataDB.get(key);
        if (fromDB != null && fromDB.event!.createdAt > threshold) {
          return fromDB;
        }

        try {
          final md = Metadata.fromEvent(
              events.firstWhere((Event event) => event.pubKey == key));

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

  Future<Metadata> load(String pubkey) {
    return this.loader.load(pubkey);
  }

  void clear() {
    this.loader.close();
    MetadataDB.deleteAll();
  }
}
