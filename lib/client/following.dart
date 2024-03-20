import "dart:async";

import "package:collection/collection.dart";

import "package:loure/client/event.dart";
import "package:loure/client/event_kind.dart";
import "package:loure/client/filter.dart";
import "package:loure/client/nip02/contact_list.dart";
import "package:loure/client/relay/relay_pool.dart";
import "package:loure/data/note_db.dart";
import "package:loure/main.dart";

class FollowingManager {
  FollowingManager();

  List<Contact> contacts = [];
  List<List<String>> relaysFor = [];

  List<Event> events = [];
  ManySubscriptionHandle? subHandle;

  final StreamController<int> newEventsCountStreamController =
      StreamController<int>();

  Stream<int> get newEventsCountStream => newEventsCountStreamController.stream;
  int newEventsCountCurrent = 0;

  void init() async {
    final cl = await contactListLoader.load(nostr.publicKey);
    this.contacts = cl.contacts; // add some randomness
    this.relaysFor = List.filled(contacts.length, [], growable: false);

    await Future.wait(this.contacts.mapIndexed((final i, final contact) async {
      final rl = await relaylistLoader.load(contact.pubkey);
      rl.write.shuffle(); // add some randomness
      this.relaysFor[i] = rl.write;
    }));

    // load notes from db
    this.events = await NoteDB.loadFromFollowing();

    final Map<String, List<String>> chosen = {}; // { relay: [pubkeys, ...] }
    for (var i = 0; i < this.contacts.length; i++) {
      final contact = this.contacts[i];

      // pick relays
      final relays = relaysFor[i];
      int picked = 0;

      // try to pick relays we have already picked
      for (final url in relays) {
        if (chosen.keys.contains(url)) {
          chosen.update(url, (contacts) {
            contacts.add(contact.pubkey);
            return contacts;
          }, ifAbsent: () => [contact.pubkey]);
          picked++;
          if (picked >= 3) break;
        }
      }

      if (picked < 3) {
        // try again but now just pick anything
        for (final url in relays) {
          chosen.update(url, (contacts) {
            contacts.add(contact.pubkey);
            return contacts;
          }, ifAbsent: () => [contact.pubkey]);
          picked++;
          if (picked >= 3) break;
        }
      }
    }

    // start an ongoing subscription
    final mostRecent = this.events.length == 0 ? 0 : this.events[0].createdAt;
    this.subHandle = pool.subscribeMany(
      chosen.keys,
      [Filter(kinds: EventKind.SUPPORTED_EVENTS, since: mostRecent)],
      onEvent: (final event) {
        if (this.events.length == 0) {
          this.events.add(event);
        } else {
          final idx = this.whereToInsert(event);
          if (idx == -1) {
            // event is already here
            return;
          }

          this.events.insert(idx, event);

          // if this event would be added to the top (in the range of all the other new events at the top
          // that weren't seen yet) notify it as a new event
          if (idx <= newEventsCountCurrent) {
            newEventsCountCurrent++;
            this.newEventsCountStreamController.add(newEventsCountCurrent);
          }
        }
      },
      filterModifier: (relay, filters) {
        filters[0].authors = chosen[relay];
        return filters;
      },
    );
  }

  // returns the index into which the event should be inserted, if it doesn't exist
  // if it exists already, returns -1 -- using a kind of binary search
  int whereToInsert(Event needle) {
    var mostRecentIdx = 0;
    var oldestIdx = this.events.length;
    var midIdx = mostRecentIdx + ((oldestIdx - mostRecentIdx) >> 1);

    while (mostRecentIdx < oldestIdx) {
      var element = this.events[midIdx];

      if (needle.createdAt > element.createdAt) {
        oldestIdx = midIdx;
        continue;
      }
      if (needle.createdAt < element.createdAt) {
        mostRecentIdx = midIdx + 1;
        continue;
      }
      if (element.id == needle.id) return -1;
      break;
    }

    return midIdx;
  }

  void contactsUpdated(final ContactList contactList) {
    // diff against the previous version
    // update the database so people we have unfollowed are not marked as follows anymore
    // also do this when a new contact list is received from contactListLoader
  }

  Iterable<Event> eventsByPubkey(String pubkey) {
    return this.events.where((final evt) => evt.pubKey == pubkey);
  }

  dispose() {
    if (this.subHandle != null) this.subHandle!.close();
    newEventsCountStreamController.close();
  }
}
