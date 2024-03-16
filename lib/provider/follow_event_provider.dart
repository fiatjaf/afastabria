import "package:flutter/material.dart";

import "package:loure/client/event_kind.dart";
import "package:loure/client/event.dart";
import "package:loure/client/nip02/contact.dart";
import "package:loure/client/nip02/cust_contact_list.dart";
import "package:loure/client/filter.dart";
import "package:loure/client/relay/relay_pool.dart";
import "package:loure/data/event_mem_box.dart";
import "package:loure/main.dart";
import "package:loure/util/find_event_interface.dart";
import "package:loure/util/pendingevents_later_function.dart";

class FollowEventProvider extends ChangeNotifier
    with PendingEventsLaterFunction
    implements FindEventInterface {
  FollowEventProvider() {
    _initTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    eventBox = EventMemBox(sortAfterAdd: false); // sortAfterAdd by call
    postsBox = EventMemBox(sortAfterAdd: false);
  }
  late int _initTime;

  late EventMemBox eventBox;
  late EventMemBox postsBox;

  ManySubscriptionHandle? subHandle;

  @override
  List<Event> findEvent(final String str, {final int? limit = 5}) {
    return eventBox.findEvent(str, limit: limit);
  }

  List<Event> eventsByPubkey(final String pubkey) {
    return eventBox.listByPubkey(pubkey);
  }

  void refresh() {
    _initTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    eventBox.clear();
    postsBox.clear();
    doQuery();

    followNewEventProvider.clear();
  }

  int lastTime() {
    return _initTime;
  }

  void deleteEvent(final String id) {
    postsBox.delete(id);
    final result = eventBox.delete(id);
    if (result) {
      notifyListeners();
    }
  }

  void doQuery({final int? until, final bool forceUserLimit = false}) {
    final filter = Filter(
      kinds: EventKind.SUPPORTED_EVENTS,
      until: until ?? _initTime,
      limit: 20,
    );
    this.unsubscribe();

    Iterable<Contact> contactList = contactListProvider.list();
    Set<String> pubkeys = {};

    // timeline pull my events too.
    pubkeys.add(nostr.publicKey);

    // TODO: outbox model
    for (final Contact contact in contactList) {
      pubkeys.add(contact.publicKey);
    }

    filter.authors = pubkeys.toList();

    final relays = [...nostr.relayList.read];
    List<Filter> Function(String, List<Filter>)? filterModifier;

    if (!this.eventBox.isEmpty()) {
      final oldestCreatedAts = this.eventBox.oldestCreatedAtByRelay(relays);
      filterModifier = (final url, final filters) {
        final filter = filters[0];
        final oca = oldestCreatedAts.createdAtMap[url];
        if (oca != null) {
          filter.until = oca;
          filter.limit = null;
          if (filter.until! < oldestCreatedAts.avCreatedAt - 60 * 60 * 18) {
            filter.since = oca - 60 * 60 * 12;
          } else if (filter.until! >
              oldestCreatedAts.avCreatedAt - 60 * 60 * 6) {
            filter.since = oca - 60 * 60 * 36;
          } else {
            filter.since = oca - 60 * 60 * 24;
          }
        }

        return filters;
      };
    }

    this.subHandle = pool.subscribeMany(
        relays,
        [
          Filter(kinds: [EventKind.TEXT_NOTE])
        ],
        filterModifier: filterModifier);
  }

  void unsubscribe() {
    if (this.subHandle != null) this.subHandle!.close();
  }

  // check if is posts (no tag e and not Mentions, TODO handle NIP27)
  static bool eventIsPost(final Event event) {
    bool isPosts = true;
    final tagLength = event.tags.length;
    for (var i = 0; i < tagLength; i++) {
      final tag = event.tags[i];
      if (tag.length > 0 && tag[0] == "e") {
        if (event.content.contains("[$i]")) {
          continue;
        }

        isPosts = false;
        break;
      }
    }

    return isPosts;
  }

  void mergeNewEvent() {
    final allEvents = followNewEventProvider.eventMemBox.all();
    final postEvnets = followNewEventProvider.eventPostMemBox.all();

    eventBox.addList(allEvents);
    postsBox.addList(postEvnets);

    // sort
    eventBox.sort();
    postsBox.sort();

    followNewEventProvider.clear();

    // update ui
    notifyListeners();
  }

  void onEvent(final Event event) {
    if (eventBox.isEmpty()) {
      laterTimeMS = 200;
    } else {
      laterTimeMS = 500;
    }
    later(event, (final list) {
      bool added = false;
      for (final e in list) {
        final result = eventBox.add(e);
        if (result) {
          // add success
          added = true;

          // check if is posts (no tag e)
          final bool isPosts = eventIsPost(e);
          if (isPosts) {
            postsBox.add(e);
          }
        }
      }

      if (added) {
        // sort
        eventBox.sort();
        postsBox.sort();

        // update ui
        notifyListeners();
      }
    }, null);
  }

  void clear() {
    this.eventBox.clear();
    this.postsBox.clear();
    this.unsubscribe();
    this.notifyListeners();
  }

  void metadataUpdatedCallback(final CustContactList? contactList) {
    if (firstLogin ||
        (eventBox.isEmpty() && contactList != null && !contactList.isEmpty())) {
      doQuery();
    }

    if (firstLogin && contactList != null && contactList.list().length > 10) {
      firstLogin = false;
    }
  }
}
