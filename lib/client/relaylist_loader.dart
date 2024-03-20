import "package:graphql_data_loader2/graphql_data_loader2.dart";

import "package:loure/client/event.dart";
import "package:loure/client/filter.dart";
import "package:loure/client/nip65/relay_list.dart";
import "package:loure/data/relaylist_db.dart";
import "package:loure/main.dart";

class RelayListLoader {
  final DataLoader<String, RelayList> _loader =
      DataLoader(batchLoad, cache: false);

  final Map<String, Future<RelayList>> _promises = {};

  final threshold =
      DateTime.now().subtract(const Duration(days: 7)).millisecondsSinceEpoch /
          1000;

  static Future<List<RelayList>> batchLoad(final Iterable<String> keys) async {
    final events = await pool.querySync(
        nostr.RELAYLIST_RELAYS, Filter(kinds: [10002], authors: keys.toList()));

    return await Future.wait(
      keys.map((final String key) async {
        try {
          final md = RelayList.fromEvent(
              events.firstWhere((final Event event) => event.pubKey == key));

          RelayListDB.upsert(md);
          return md;
        } catch (err) {
          // people without relay list will always be found on some set of default relays from damus
          return RelayList(key, [
            "wss://relay.damus.io",
            "wss://nostr.wine",
            "wss://nos.lol"
          ], [
            "wss://relay.damus.io",
            "wss://nos.lol",
            "wss://nostr.einundzwanzig.space",
            "wss://yabu.me",
            "wss://relay.siamstr.com"
          ]);
        }
      }),
    );
  }

  Future<RelayList> load(final String pubkey) {
    return this._promises.putIfAbsent(pubkey, () {
      return RelayListDB.get(pubkey).then((RelayList? md) {
        if (md != null && md.event!.createdAt > threshold) {
          return md;
        }
        return this._loader.load(pubkey);
      });
    });
  }

  void invalidate(final String pubkey) {
    RelayListDB.delete(pubkey);
    this._promises.remove(pubkey);
  }
}
