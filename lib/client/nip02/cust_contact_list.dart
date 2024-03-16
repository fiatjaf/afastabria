import "package:loure/client/nip02/contact.dart";

class CustContactList {
  CustContactList()
      : _contacts = {},
        _followedTags = {},
        _followedCommunitys = {};

  factory CustContactList.fromJson(final List<List<String>> tags) {
    Map<String, Contact> contacts = {};
    Map<String, int> followedTags = {};
    Map<String, int> followedCommunitys = {};
    for (final tag in tags) {
      final length = tag.length;
      if (length == 0) {
        continue;
      }

      final t = tag[0];
      if (t == "p") {
        String url = "";
        String petname = "";
        if (length > 2) {
          url = tag[2];
        }
        if (length > 3) {
          petname = tag[3];
        }
        final contact = Contact(publicKey: tag[1], url: url, petname: petname);
        contacts[contact.publicKey] = contact;
      } else if (t == "t" && length > 1) {
        final tagName = tag[1];
        followedTags[tagName] = 1;
      } else if (t == "a" && length > 1) {
        final id = tag[1];
        followedCommunitys[id] = 1;
      }
    }
    return CustContactList._(contacts, followedTags, followedCommunitys);
  }

  CustContactList._(
      this._contacts, this._followedTags, this._followedCommunitys);
  final Map<String, Contact> _contacts;
  final Map<String, int> _followedTags;
  final Map<String, int> _followedCommunitys;

  List<List<String>> toTags() {
    List<List<String>> result = [];
    for (final Contact contact in _contacts.values) {
      result.add(["p", contact.publicKey, contact.url, contact.petname]);
    }
    for (final followedTag in _followedTags.keys) {
      result.add(["t", followedTag]);
    }
    for (final id in _followedCommunitys.keys) {
      result.add(["a", id]);
    }
    return result;
  }

  void add(final Contact contact) {
    _contacts[contact.publicKey] = contact;
  }

  Contact? get(final String publicKey) {
    return _contacts[publicKey];
  }

  Contact? remove(final String publicKey) {
    return _contacts.remove(publicKey);
  }

  Iterable<Contact> list() {
    return _contacts.values;
  }

  bool isEmpty() {
    return _contacts.isEmpty;
  }

  int total() {
    return _contacts.length;
  }

  void clear() {
    _contacts.clear();
  }

  bool containsTag(final String tagName) {
    return _followedTags.containsKey(tagName);
  }

  void addTag(final String tagName) {
    _followedTags[tagName] = 1;
  }

  void removeTag(final String tagName) {
    _followedTags.remove(tagName);
  }

  int totalFollowedTags() {
    return _followedTags.length;
  }

  Iterable<String> tagList() {
    return _followedTags.keys;
  }

  bool containsCommunity(final String id) {
    return _followedCommunitys.containsKey(id);
  }

  void addCommunity(final String id) {
    _followedCommunitys[id] = 1;
  }

  void removeCommunity(final String id) {
    _followedCommunitys.remove(id);
  }

  int totalFollowedCommunities() {
    return _followedCommunitys.length;
  }

  Iterable<String> followedCommunitiesList() {
    return _followedCommunitys.keys;
  }
}
