import 'package:nostrmo/util/string_util.dart';

import 'client_utils/keys.dart';
import 'event.dart';
import 'event_kind.dart';
import 'nip02/cust_contact_list.dart';
import 'relay/relay.dart';
import 'relay/relay_pool.dart';

class Nostr {
  late String _privateKey;
  late String _publicKey;
  late RelayPool _pool;

  Nostr(String privateKey, {bool eventVerification = false}) {
    if (keyIsValid(privateKey)) {
      _privateKey = privateKey;
      _publicKey = getPublicKey(privateKey);
    } else {
      throw const FormatException("invalid key");
    }
    _pool = RelayPool(this, eventVerification);
  }

  String get privateKey => _privateKey;
  String get publicKey => _publicKey;

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
    return this.broadcast(event);
  }

  Event broadcast(Event event) {
    _pool.send(["EVENT", event.toJson()]);
    return event;
  }

  void close() {
    _pool.removeAll();
  }

  void addInitQuery(List<Map<String, dynamic>> filters, Function(Event) onEvent,
      {String? id, Function? onComplete}) {
    _pool.addInitQuery(filters, onEvent, id: id, onComplete: onComplete);
  }

  String subscribe(List<Map<String, dynamic>> filters, Function(Event) onEvent,
      {String? id}) {
    return _pool.subscribe(filters, onEvent, id: id);
  }

  void unsubscribe(String id) {
    _pool.unsubscribe(id);
  }

  String query(List<Map<String, dynamic>> filters, Function(Event) onEvent,
      {String? id, Function? onComplete}) {
    return _pool.query(filters, onEvent, id: id, onComplete: onComplete);
  }

  String queryByFilters(Map<String, List<Map<String, dynamic>>> filtersMap,
      Function(Event) onEvent,
      {String? id, Function? onComplete}) {
    return _pool.queryByFilters(filtersMap, onEvent,
        id: id, onComplete: onComplete);
  }

  Future<bool> addRelay(
    Relay relay, {
    bool autoSubscribe = false,
    bool init = false,
  }) async {
    return await _pool.add(relay, autoSubscribe: autoSubscribe, init: init);
  }

  void removeRelay(String url) {
    _pool.remove(url);
  }

  List<Relay> activeRelays() {
    return _pool.activeRelays();
  }

  Relay? getRelay(String url) {
    return _pool.getRelay(url);
  }
}
