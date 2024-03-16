import "dart:convert";

import "package:flutter/material.dart";
import "package:loure/router/tag/topic_map.dart";

import "package:loure/client/event_kind.dart";
import "package:loure/client/event.dart";
import "package:loure/client/nip02/contact.dart";
import "package:loure/client/nip02/cust_contact_list.dart";
import "package:loure/client/filter.dart";
import "package:loure/main.dart";
import "package:loure/util/string_util.dart";
import "package:loure/provider/data_util.dart";

class ContactListProvider extends ChangeNotifier {
  Event? _event;
  String content = "";
  CustContactList? _contactList;

  void reload() {
    String? pubkey;
    pubkey = nostr.publicKey;

    final str = sharedPreferences.getString(DataKey.CONTACT_LISTS);
    print("str $str");
    if (str != null && str != "") {
      final jsonMap = jsonDecode(str);

      if (jsonMap is Map<String, dynamic>) {
        String? eventStr;
        if (StringUtil.isNotBlank(pubkey)) {
          eventStr = jsonMap[pubkey];
        } else if (jsonMap.length == 1) {
          eventStr = jsonMap.entries.first.value as String;
        }

        if (eventStr != null) {
          final eventMap = jsonDecode(eventStr);
          this._event = Event.fromJson(eventMap);
          this._contactList = CustContactList.fromJson(this._event!.tags);
          this.content = this._event!.content;

          return;
        }
      }
    }

    this._contactList = CustContactList();
  }

  void clearCurrentContactList() {
    final pubkey = nostr.publicKey;
    final str = sharedPreferences.getString(DataKey.CONTACT_LISTS);
    if (StringUtil.isNotBlank(str)) {
      final jsonMap = jsonDecode(str!);
      if (jsonMap is Map) {
        jsonMap.remove(pubkey);

        final jsonStr = jsonEncode(jsonMap);
        sharedPreferences.setString(DataKey.CONTACT_LISTS, jsonStr);
      }
    }
  }

  void query() {
    final filter = Filter(
        kinds: [EventKind.CONTACT_LIST], limit: 1, authors: [nostr.publicKey]);

    pool.subscribeManyEose(nostr.CONTACT_RELAYS, [filter], onEvent: _onEvent);
  }

  void _onEvent(final Event e) {
    if (e.kind == EventKind.CONTACT_LIST) {
      if (_event == null || e.createdAt > _event!.createdAt) {
        _event = e;
        _contactList = CustContactList.fromJson(e.tags);
        content = e.content;
        _saveAndNotify();

        // relayProvider.relayUpdateByContactListEvent(e);
      }
    }
  }

  void _saveAndNotify({final bool notify = true}) {
    final eventJsonMap = _event!.toJson();
    final eventJsonStr = jsonEncode(eventJsonMap);

    final pubkey = nostr.publicKey;
    Map<String, dynamic>? allJsonMap;

    final str = sharedPreferences.getString(DataKey.CONTACT_LISTS);
    if (str != "") {
      allJsonMap = jsonDecode(str!);
    }
    allJsonMap ??= {};

    allJsonMap[pubkey] = eventJsonStr;
    final jsonStr = jsonEncode(allJsonMap);

    sharedPreferences.setString(DataKey.CONTACT_LISTS, jsonStr);

    if (notify) {
      notifyListeners();
      followEventProvider.metadataUpdatedCallback(_contactList);
    }
  }

  int total() {
    return _contactList!.total();
  }

  void addContact(final Contact contact) {
    _contactList!.add(contact);
    _event = nostr.sendContactList(_contactList!, content);

    _saveAndNotify();
  }

  void removeContact(final String pubKey) {
    _contactList!.remove(pubKey);
    _event = nostr.sendContactList(_contactList!, content);

    _saveAndNotify();
  }

  void updateContacts(final CustContactList contactList) {
    _contactList = contactList;
    _event = nostr.sendContactList(contactList, content);

    _saveAndNotify();
  }

  CustContactList? get contactList => _contactList;

  Iterable<Contact> list() {
    return _contactList!.list();
  }

  Contact? getContact(final String pubKey) {
    return _contactList!.get(pubKey);
  }

  void clear() {
    _event = null;
    _contactList!.clear();
    content = "";
    clearCurrentContactList();

    notifyListeners();
  }

  bool containTag(final String tag) {
    final list = TopicMap.getList(tag);
    if (list != null) {
      for (final t in list) {
        final exist = _contactList!.containsTag(t);
        if (exist) {
          return true;
        }
      }
      return false;
    } else {
      return _contactList!.containsTag(tag);
    }
  }

  void addTag(final String tag) {
    _contactList!.addTag(tag);
    _event = nostr.sendContactList(_contactList!, content);

    _saveAndNotify();
  }

  void removeTag(final String tag) {
    _contactList!.removeTag(tag);
    _event = nostr.sendContactList(_contactList!, content);

    _saveAndNotify();
  }

  int totalFollowedTags() {
    return _contactList!.totalFollowedTags();
  }

  Iterable<String> tagList() {
    return _contactList!.tagList();
  }

  bool containCommunity(final String id) {
    return _contactList!.containsCommunity(id);
  }

  void addCommunity(final String tag) {
    _contactList!.addCommunity(tag);
    _event = nostr.sendContactList(_contactList!, content);

    _saveAndNotify();
  }

  void removeCommunity(final String tag) {
    _contactList!.removeCommunity(tag);
    _event = nostr.sendContactList(_contactList!, content);

    _saveAndNotify();
  }

  int totalfollowedCommunities() {
    return _contactList!.totalFollowedCommunities();
  }

  Iterable<String> followedCommunitiesList() {
    return _contactList!.followedCommunitiesList();
  }

  void updateRelaysContent(final String relaysContent) {
    content = relaysContent;
    _event = nostr.sendContactList(_contactList!, content);

    _saveAndNotify(notify: false);
  }
}
