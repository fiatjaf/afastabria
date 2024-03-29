import "dart:async";

import "package:collection/collection.dart";
import "package:flutter/material.dart";

import "package:loure/client/event.dart";
import "package:loure/client/event_kind.dart";
import "package:loure/client/filter.dart";
import "package:loure/client/relay/relay_pool.dart";
import "package:loure/data/db.dart";
import "package:loure/data/note_db.dart";
import "package:loure/main.dart";

class FollowingManager extends ChangeNotifier {
  FollowingManager();

  Set<String> follows = {};
  List<List<String>> relaysFor = [];

  ManySubscriptionHandle? subHandle;
  final List<Event> unmerged = [];

  List<Event> events = [];
  final ValueNotifier<int> newEvents = ValueNotifier(0);

  void init() async {
    final cl = await contactListLoader.load(nostr.publicKey);
    this.follows = cl.contacts.map((final follow) => follow.pubkey).toSet();
    this.relaysFor = List.filled(this.follows.length, [], growable: false);

    await Future.wait(this.follows.mapIndexed((final i, final follow) async {
      final rl = await relaylistLoader.load(follow);
      rl.write.shuffle(); // add some randomness
      this.relaysFor[i] = rl.write;
    }));

    // load notes from db
    this.events = await NoteDB.loadFromFollowing();
    this.notifyListeners();

    // start subscriptions
    this.subHandle = this.pickRelaysAndStartSubscriptions(
        this.follows, this.events.length == 0 ? 0 : this.events[0].createdAt);

    // update our local stuff when our contact list changes
    contactListProvider.addListener(this.contactsUpdated);
  }

  ManySubscriptionHandle pickRelaysAndStartSubscriptions(
      final Set<String> follows, int since) {
    final Map<String, List<String>> chosen = {}; // { relay: [pubkeys, ...] }
    var i = -1;
    for (final follow in follows) {
      i++;
      // pick relays
      final relays = relaysFor[i];
      int picked = 0;

      // try to pick relays we have already picked
      for (final url in relays) {
        if (chosen.keys.contains(url)) {
          chosen.update(url, (contacts) {
            contacts.add(follow);
            return contacts;
          }, ifAbsent: () => [follow]);
          picked++;
          if (picked >= 3) break;
        }
      }

      if (picked < 3) {
        // try again but now just pick anything
        for (final url in relays) {
          chosen.update(url, (contacts) {
            contacts.add(follow);
            return contacts;
          }, ifAbsent: () => [follow]);
          picked++;
          if (picked >= 3) break;
        }
      }
    }

    // start an ongoing subscription
    print("subscribing since $since to $chosen");
    return pool.subscribeMany(
      chosen.keys,
      [
        Filter(kinds: [EventKind.TEXT_NOTE, EventKind.REPOST], since: since)
      ],
      onEvent: this.handleEvent,
      id: "following",
      filterModifier: (relay, filters) {
        filters[0].authors = chosen[relay];
        return filters;
      },
    );
  }

  void handleEvent(final event) {
    this.unmerged.add(event);
    this.newEvents.value++;
    this.newEvents;
  }

  mergeNewNotes() {
    DB.transaction((final txn) async {
      for (final event in this.unmerged) {
        final idx = whereToInsert(this.events, event);
        if (idx == -1) {
          // event is already here
          continue;
        }
        this.events.insert(idx, event);

        await nostr.processDownloadedEvent(event, db: txn);
      }
    });
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

  void contactsUpdated() {
    // diff against the previous version
    final next = contactListProvider.contactList!.contacts;
    final Set<String> added = {};
    final Set<String> notRemoved = {};
    for (final follow in next) {
      if (this.follows.contains(follow.pubkey)) {
        notRemoved.add(follow.pubkey);
      } else {
        added.add(follow.pubkey);
      }
    }
    final removed = this.follows.difference(notRemoved);

    // update the database so people we have unfollowed are not marked as follows anymore
    NoteDB.updateFollow(added, true);
    NoteDB.updateFollow(removed, false);

    if (this.subHandle != null) {
      // remove deleted people from filters on existing subscriptions
      this.subHandle!.editSubsAndMaybeClose((final sub) {
        sub.filters[0].authors!.removeWhere(removed.contains);
        return sub.filters[0].authors!.length == 0;
      });

      // start following the new guys
      this.subHandle?.merge(this.pickRelaysAndStartSubscriptions(added, 0));
    }

    // update locally
    this.follows = added.union(notRemoved);

    // TODO: also do this when a new contact list is received from contactListLoader
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
