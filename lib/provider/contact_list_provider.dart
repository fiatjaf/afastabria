import "package:flutter/material.dart";

import "package:loure/client/nip02/contact_list.dart";
import "package:loure/main.dart";

class ContactListProvider extends ChangeNotifier {
  ContactList? contactList;

  void init() async {
    this.contactList = await contactListLoader.load(nostr.publicKey);
    this.notifyListeners();
  }

  void addContact(final Contact contact) {
    this.contactList!.add(contact);
    nostr.sendContactList(this.contactList!);
    this.notifyListeners();
  }

  void removeContact(final String pubkey) {
    this.contactList!.remove(pubkey);
    nostr.sendContactList(this.contactList!);
    this.notifyListeners();
  }

  void updateContacts(final ContactList contactList) {
    this.contactList = contactList;
    nostr.sendContactList(contactList);
    this.notifyListeners();
  }

  Contact? getContact(final String pubkey) {
    return this.contactList!.get(pubkey);
  }

  void clear() {
    this.contactList!.clear();
    this.notifyListeners();
  }

  bool containTag(final String tag) {
    return false;
  }

  void addTag(final String tag) {}

  void removeTag(final String tag) {}

  Iterable<String> tagList() {
    return [];
  }

  bool containCommunity(final String id) {
    return false;
  }

  void addCommunity(final String tag) {}

  void removeCommunity(final String tag) {}

  Iterable<String> followedCommunitiesList() {
    return [];
  }
}
