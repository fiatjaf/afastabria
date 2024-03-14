import 'package:nostrmo/util/string_util.dart';
import 'package:nostrmo/client/event_kind.dart';
import 'package:nostrmo/main.dart';

import 'client_utils/keys.dart';
import 'event.dart';
import 'relay/relay_pool.dart';
import 'nip02/cust_contact_list.dart';

class Nostr {
  late String _privateKey;
  late String _publicKey;
  late RelayPool pool;

  final eventIndex = <String, Event>{};

  Nostr(String privateKey) {
    if (keyIsValid(privateKey)) {
      _privateKey = privateKey;
      _publicKey = getPublicKey(privateKey);
    } else {
      throw const FormatException("invalid key");
    }
    this.pool = RelayPool();
  }

  String get privateKey => _privateKey;
  String get publicKey => _publicKey;

  void init(String secretKey) {
    var nostr = Nostr(secretKey);

    // add initQuery
    var dmInitFuture = dmProvider.initDMSessions(nostr.publicKey);
    contactListProvider.reload(targetNostr: nostr);
    contactListProvider.query(targetNostr: nostr);
    followEventProvider.doQuery(targetNostr: nostr, initQuery: true);
    mentionMeProvider.doQuery(targetNostr: nostr, initQuery: true);
    dmInitFuture.then((_) {
      dmProvider.query(targetNostr: nostr, initQuery: true);
    });

    listProvider.load(
        nostr.publicKey, [EventKind.BOOKMARKS_LIST, EventKind.EMOJIS_LIST],
        targetNostr: nostr, initQuery: true);
    badgeProvider.reload(targetNostr: nostr, initQuery: true);
  }

  Event? sendLike(String id) {
    Event event = Event.finalize(
        this._privateKey,
        EventKind.REACTION,
        [
          ["e", id]
        ],
        "+");
    return this.broadcast(event);
  }

  Event? deleteEvent(String eventId) {
    Event event = Event.finalize(
        this._privateKey,
        EventKind.EVENT_DELETION,
        [
          ["e", eventId]
        ],
        "delete");
    return this.broadcast(event);
  }

  void deleteEvents(List<String> eventIds) {
    List<List<String>> tags = [];
    for (var eventId in eventIds) {
      tags.add(["e", eventId]);
    }

    Event event =
        Event.finalize(_privateKey, EventKind.EVENT_DELETION, tags, "delete");
    this.broadcast(event);
  }

  Event sendRepost(String id, {String? relayAddr, String content = ""}) {
    List<String> tag = ["e", id];
    if (StringUtil.isNotBlank(relayAddr)) {
      tag.add(relayAddr!);
    }
    Event event = Event.finalize(_privateKey, EventKind.REPOST, [tag], content);
    return this.broadcast(event);
  }

  Event sendTextNote(String text, [List<List<String>> tags = const []]) {
    Event event = Event.finalize(_privateKey, EventKind.TEXT_NOTE, tags, text);
    return this.broadcast(event);
  }

  Event sendContactList(CustContactList contacts, String content) {
    final tags = contacts.toTags();
    final event =
        Event.finalize(_privateKey, EventKind.CONTACT_LIST, tags, content);
    this.pool.send([], ["EVENT", event.toJson()]);
  }

  Event broadcast(Event event) {
    return event;
  }
}
