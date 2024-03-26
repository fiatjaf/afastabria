import "dart:convert";

import "package:loure/client/aid.dart";
import "package:loure/client/event_kind.dart";
import "package:loure/client/filter.dart";
import "package:loure/consts/base_consts.dart";
import "package:loure/data/contactlist_db.dart";
import "package:loure/data/metadata.dart";
import "package:loure/data/metadata_db.dart";
import "package:loure/data/note_db.dart";
import "package:loure/data/relaylist_db.dart";
import "package:loure/main.dart";
import "package:loure/client/client_utils/keys.dart";
import "package:loure/client/event.dart";
import "package:loure/client/nip02/contact_list.dart";
import "package:loure/client/nip65/relay_list.dart";

const ONE = "0000000000000000000000000000000000000000000000000000000000000001";

class Nostr {
  Nostr(this.privateKey) : this.publicKey = getPublicKey(privateKey);
  factory Nostr.empty() {
    return Nostr(ONE);
  }

  final String privateKey;
  final String publicKey;

  bool isEmpty() {
    return this.privateKey == ONE;
  }

  RelayList relayList = RelayList("", [
    "wss://nostr.wine",
    "wss://nostr21.com",
    "wss://nostr.mom",
    "wss://relay.snort.social",
  ], [
    "wss://nos.lol",
    "wss://offchain.pub",
    "wss://relay.damus.io",
    "wss://relay.primal.net",
  ]);

  final idIndex = <String, Event>{};
  final addressIndex = <String, Event>{};

  void init() {
    pool
        .querySync(RELAYLIST_RELAYS,
            Filter(kinds: [10002], authors: [nostr.publicKey]))
        .then((final Iterable<Event> evts) {
      if (evts.length == 0) return;

      final Event latest = evts.reduce((final Event a, final Event b) {
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
    "wss://relay.noswhere.com",
    "wss://relay.damus.io",
  ];
  final List<String> CONTACT_RELAYS = [
    "wss://purplepag.es",
    "wss://relay.nostr.band",
    "wss://relay.nos.social"
  ];
  final List<String> RELAYLIST_RELAYS = [
    "wss://relay.primal.net",
    "wss://purplepag.es",
    "wss://relay.snort.social",
    "wss://nos.lol"
  ];
  final List<String> SEARCH_RELAYS = [
    "wss://relay.noswhere.com",
    "wss://relay.nostr.band",
    "wss://nostr.wine",
    "wss://search.nos.today"
  ];
  final List<String> RANDOM_RELAYS = [
    "wss://relay.primal.net",
    "wss://relay.damus.io",
    "wss://nostr.mom",
    "wss://offchain.pub",
  ];
  final List<String> BLASTR = ["wss://nostr.mutinywallet.com"];

  Future<Event?> getByID(final String id) async {
    Event? evt = nostr.idIndex[id];
    if (evt != null) {
      return evt;
    }

    evt = await NoteDB.get(id);
    if (evt != null) {
      return evt;
    }

    return await pool.querySingle(
      nostr.ID_RELAYS,
      Filter(ids: [id]),
      id: "specific-i",
    );
  }

  Future<Event?> getByAddress(final AId aid,
      {final Iterable<String>? relays}) async {
    final tag = aid.toTag();
    final evt = nostr.addressIndex[tag];
    if (evt != null) {
      return evt;
    }

    return pool.querySingle(
      relays == null
          ? nostr.RANDOM_RELAYS
          : [...relays, ...nostr.RANDOM_RELAYS],
      aid.toFilter(),
      id: "specific-a",
    );
  }

  void updateIndexesAndSource(final Event event, final String relayURL) {
    this.idIndex.update(event.id, (final Event curr) {
      curr.sources.add(relayURL);
      return curr;
    }, ifAbsent: () {
      event.sources.add(relayURL);
      return event;
    });

    if (event.kind >= 30000 && event.kind < 40000) {
      final aid = AId(
        kind: event.kind,
        pubkey: event.pubkey,
        identifier: event.tags.firstWhere(
            (final tag) => tag.firstOrNull == "d" && tag.length >= 2,
            orElse: () => ["", ""])[1],
      );
      this.addressIndex[aid.toTag()] = event;
    }
  }

  Event? sendLike(final String id) {
    final target = nostr.idIndex[id];
    if (target == null) {
      return null;
    }

    final Event event = Event.finalize(
        this.privateKey,
        EventKind.REACTION,
        [
          ["e", id, target.sources.first]
        ],
        "+");

    pool.publish(target.sources, event);
    return event;
  }

  void deleteEvent(final String id) {
    final relays = [...BLASTR];
    final target = nostr.idIndex[id];
    if (target != null) {
      relays.addAll(target.sources);
    }

    final Event event = Event.finalize(
        this.privateKey,
        EventKind.EVENT_DELETION,
        [
          ["e", id]
        ],
        "");
    pool.publish(relays, event);
  }

  void deleteEvents(final List<String> ids) {
    final relays = BLASTR.toSet();

    List<List<String>> tags = [];
    for (final id in ids) {
      final target = nostr.idIndex[id];
      if (target != null) {
        relays.addAll(target.sources);
      }

      tags.add(["e", id]);
    }

    final Event event =
        Event.finalize(this.privateKey, EventKind.EVENT_DELETION, tags, "");
    pool.publish(relays, event);
  }

  Event? sendRepost(final String id) {
    final target = nostr.idIndex[id];
    if (target == null) {
      return null;
    }

    final Event event = Event.finalize(
        this.privateKey,
        EventKind.REPOST,
        [
          ["e", id, target.sources.first]
        ],
        jsonEncode(target.toJson()));

    pool.publish(this.relayList.write, event);

    if (settingProvider.broadcaseWhenBoost == OpenStatus.OPEN) {
      pool.publish(nostr.relayList.write, target);
    }

    return event;
  }

  Event sendTextNote(final String text,
      [final List<List<String>> tags = const []]) {
    final Event event =
        Event.finalize(this.privateKey, EventKind.TEXT_NOTE, tags, text);
    pool.publish(this.relayList.write, event);
    return event;
  }

  sendMetadata(final Metadata metadata) async {
    final event = await metadata.toEvent(Event.getSigner(nostr.privateKey));
    pool.publish([...this.relayList.write, ...METADATA_RELAYS], event);
    MetadataDB.upsert(metadata);
    metadataLoader.invalidate(metadata.pubkey);
    return event;
  }

  sendContactList(final ContactList cl) async {
    final event = await cl.toEvent(Event.getSigner(nostr.privateKey));
    pool.publish([...this.relayList.write, ...CONTACT_RELAYS], event);
    ContactListDB.upsert(cl);
    contactListLoader.invalidate(cl.pubkey);
    return event;
  }

  sendRelayList() async {
    final event =
        await this.relayList.toEvent(Event.getSigner(nostr.privateKey));
    pool.publish([...this.relayList.write, ...RELAYLIST_RELAYS], event);
    RelayListDB.upsert(this.relayList);
    relaylistLoader.invalidate(this.relayList.pubkey);
    return event;
  }

  Event sendList(
      final int kind, final List<List<String>> tags, final String content) {
    final event = Event.finalize(this.privateKey, kind, tags, content);
    pool.publish(this.relayList.write, event);
    return event;
  }
}
