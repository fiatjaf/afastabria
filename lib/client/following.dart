import "dart:async";

import "package:collection/collection.dart";
import "package:flutter/material.dart";

import "package:loure/client/event.dart";
import "package:loure/client/event_kind.dart";
import "package:loure/client/filter.dart";
import "package:loure/client/nip02/contact_list.dart";
import "package:loure/client/relay/relay_pool.dart";
import "package:loure/data/note_db.dart";
import "package:loure/main.dart";

class FollowingManager extends ChangeNotifier {
  FollowingManager();

  List<Contact> contacts = [];
  List<List<String>> relaysFor = [];

  ManySubscriptionHandle? subHandle;
  final List<Event> unmerged = [];

  List<Event> events = [];
  final ValueNotifier<int> newEvents = ValueNotifier(0);

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
    print("subscribing $mostRecent $chosen");
    this.subHandle = pool.subscribeMany(
      chosen.keys,
      [Filter(kinds: EventKind.SUPPORTED_EVENTS, since: mostRecent)],
      onEvent: (final event) {
        this.unmerged.add(event);
        this.newEvents.value++;
        this.newEvents;
      },
      id: "following-initial",
      filterModifier: (relay, filters) {
        filters[0].authors = chosen[relay];
        return filters;
      },
    );
  }

  mergeNewNotes() {
    for (final event in this.unmerged) {
      final idx = whereToInsert(this.events, event);
      if (idx == -1) {
        // event is already here
        continue;
      }
      this.events.insert(idx, event);
    }
    this.notifyListeners();

    this.unmerged.clear();
    this.newEvents.value = 0;
  }

  // returns the index into which the event should be inserted, if it doesn't exist
  // if it exists already, returns -1 -- using a kind of binary search
  static int whereToInsert(List<Event> destination, Event needle) {
    var mostRecentIdx = 0;
    var oldestIdx = destination.length;
    var midIdx = mostRecentIdx + ((oldestIdx - mostRecentIdx) >> 1);

    while (mostRecentIdx < oldestIdx) {
      midIdx = mostRecentIdx + ((oldestIdx - mostRecentIdx) >> 1);
      var element = destination[midIdx];

      if (needle.createdAt > element.createdAt) {
        oldestIdx = midIdx;
        continue;
      }
      if (needle.createdAt < element.createdAt) {
        mostRecentIdx = midIdx + 1;
        continue;
      }
      if (element.id == needle.id) {
        return -1; // we already have this element, so return -1
      }
      break; // we don't have it, but we found the best point possible
    }

    return midIdx;
  }

  void contactsUpdated(final ContactList contactList) {
    // diff against the previous version
    // update the database so people we have unfollowed are not marked as follows anymore
    // also do this when a new contact list is received from contactListLoader
  }

  Iterable<Event> eventsByPubkey(String pubkey) {
    return this.events.where((final evt) => evt.pubkey == pubkey);
  }

  @override
  dispose() {
    super.dispose();
    if (this.subHandle != null) this.subHandle!.close();
  }
}
