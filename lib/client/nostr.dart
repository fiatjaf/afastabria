import 'dart:convert';

import 'package:nostrmo/client/event_kind.dart';
import 'package:nostrmo/client/filter.dart';
import 'package:nostrmo/consts/base_consts.dart';
import 'package:nostrmo/main.dart';

import 'package:nostrmo/client/client_utils/keys.dart';
import 'package:nostrmo/client/event.dart';
import 'package:nostrmo/client/relay/relay_pool.dart';
import 'package:nostrmo/client/nip02/cust_contact_list.dart';
import 'package:nostrmo/client/nip65/relay_list.dart';

class Nostr {
  late String privateKey;
  late String publicKey;
  late RelayPool pool;

  late RelayList relayList;

  final eventIndex = <String, Event>{};

  Nostr(String privateKey) {
    if (keyIsValid(privateKey)) {
      privateKey = privateKey;
      publicKey = getPublicKey(privateKey);
    } else {
      throw const FormatException("invalid key");
    }
    this.pool = RelayPool();
  }

  void init(String secretKey) {
    contactListProvider.reload(targetNostr: this);
    contactListProvider.query(targetNostr: this);
    followEventProvider.doQuery(targetNostr: this, initQuery: true);
    mentionMeProvider.doQuery(targetNostr: this, initQuery: true);
    dmProvider.initDMSessions(this.publicKey).then((_) {
      dmProvider.query(targetNostr: this, initQuery: true);
    });

    bookmarkProvider.init();
    badgeProvider.reload(targetNostr: this, initQuery: true);

    this
        .pool
        .querySync(RELAYLIST_RELAYS,
            Filter(kinds: [10002], authors: [nostr.publicKey]))
        .then((Iterable<Event> evts) {
      if (evts.length == 0) {
        return RelayList([
          "wss://nostr.wine",
          "wss://nostr21.com",
          "wss://nostr.mom",
          "wss://pyramid.fiatjaf.com",
          "wss://relay.snort.social",
        ], [
          "wss://nos.lol",
          "wss://offchain.pub",
          "wss://relay.damus.io",
          "wss://relay.primal.net",
        ]);
      }

      Event latest = evts.reduce((Event a, Event b) {
        if (a.createdAt > b.createdAt) {
          return a;
        } else {
          return b;
        }
      });
      relayList = RelayList.fromEvent(latest);
    });
  }

  final List<String> METADATA_RELAYS = [
    "wss://purplepag.es",
    "wss://relay.snort.social",
    "wss://relay.nos.social"
  ];
  final List<String> ID_RELAYS = [
    "wss://cache2.primal.net/v1",
    "wss://relay.nostr.band",
    "wss://relay.noswhere.com"
        "wss://relay.damus.io",
  ];
  final List<String> CONTACT_RELAYS = [
    "wss://purplepag.es",
    "wss://relay.damus.io",
    "wss://relay.nos.social"
  ];
  final List<String> RELAYLIST_RELAYS = [
    "wss://relay.primal.net",
    "wss://purplepag.es",
    "wss://relay.snort.social",
    "wss://nos.lol"
  ];
  final List<String> BLASTR = ["wss://nostr.mutinywallet.com"];

  Event? sendLike(String id) {
    var target = nostr.eventIndex[id];
    if (target == null) {
      return null;
    }

    Event event = Event.finalize(
        this.privateKey,
        EventKind.REACTION,
        [
          ["e", id, target.sources.first]
        ],
        "+");

    this.pool.publish(target.sources, event);
    return event;
  }

  void deleteEvent(String id) {
    var relays = [...BLASTR];
    var target = nostr.eventIndex[id];
    if (target != null) {
      relays.addAll(target.sources);
    }

    Event event = Event.finalize(
        this.privateKey,
        EventKind.EVENT_DELETION,
        [
          ["e", id]
        ],
        "");
    this.pool.publish(relays, event);
  }

  void deleteEvents(List<String> ids) {
    var relays = BLASTR.toSet();

    List<List<String>> tags = [];
    for (var id in ids) {
      var target = nostr.eventIndex[id];
      if (target != null) {
        relays.addAll(target.sources);
      }

      tags.add(["e", id]);
    }

    Event event = Event.finalize(
        this.privateKey, EventKind.EVENT_DELETION, tags, "delete");
    this.pool.publish(relays, event);
  }

  Event? sendRepost(String id) {
    var target = nostr.eventIndex[id];
    if (target == null) {
      return null;
    }

    Event event = Event.finalize(
        this.privateKey,
        EventKind.REPOST,
        [
          ["e", id, target.sources.first]
        ],
        jsonEncode(target.toJson()));

    this.pool.publish(this.relayList.write, event);

    if (settingProvider.broadcaseWhenBoost == OpenStatus.OPEN) {
      nostr.pool.publish(nostr.relayList.write, target);
    }

    return event;
  }

  Event sendTextNote(String text, [List<List<String>> tags = const []]) {
    Event event =
        Event.finalize(this.privateKey, EventKind.TEXT_NOTE, tags, text);
    this.pool.publish(this.relayList.write, event);
    return event;
  }

  Event sendContactList(CustContactList contacts, String content) {
    final tags = contacts.toTags();
    final event =
        Event.finalize(this.privateKey, EventKind.CONTACT_LIST, tags, content);
    this.pool.publish([...this.relayList.write, ...CONTACT_RELAYS], event);
    return event;
  }

  Event sendRelayList(String content) {
    var event = this.relayList.toEvent(nostr.privateKey);
    this.pool.publish([...this.relayList.write, ...RELAYLIST_RELAYS], event);
    return event;
  }

  Event sendList(int kind, List<List<String>> tags, String content) {
    final event = Event.finalize(this.privateKey, kind, tags, content);
    this.pool.publish(this.relayList.write, event);
    return event;
  }
}
