import "package:graphql_data_loader2/graphql_data_loader2.dart";

import "package:loure/client/event.dart";
import "package:loure/client/filter.dart";
import "package:loure/client/nip02/contact_list.dart";
import "package:loure/data/contactlist_db.dart";
import "package:loure/main.dart";

class ContactListLoader {
  final DataLoader<String, ContactList> _loader =
      DataLoader(batchLoad, cache: false);

  final Map<String, Future<ContactList>> _promises = {};

  final threshold =
      DateTime.now().subtract(const Duration(days: 14)).millisecondsSinceEpoch /
          1000;

  static Future<List<ContactList>> batchLoad(
      final Iterable<String> keys) async {
    final events = await pool.querySync(
        nostr.METADATA_RELAYS, Filter(kinds: [3], authors: keys.toList()));

    return await Future.wait(
      keys.map((final String key) async {
        try {
          final md = ContactList.fromEvent(
              events.firstWhere((final Event event) => event.pubKey == key));

          ContactListDB.upsert(md);
          return md;
        } catch (err) {
          return ContactList.blank(key);
        }
      }),
    );
  }

  Future<ContactList> load(final String pubkey) {
    return this._promises.putIfAbsent(pubkey, () {
      return ContactListDB.get(pubkey).then((ContactList? md) {
        if (md != null && md.event!.createdAt > threshold) {
          return md;
        }
        return this._loader.load(pubkey);
      });
    });
  }

  void invalidate(final String pubkey) {
    ContactListDB.delete(pubkey);
    this._promises.remove(pubkey);
  }
}
