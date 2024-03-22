import "package:collection/collection.dart";
import "package:loure/client/event.dart";

class ContactList {
  ContactList(this.pubkey, this.contacts, {this.event});

  ContactList.blank(this.pubkey)
      : this.contacts = [],
        this.event = null;

  factory ContactList.fromEvent(Event event) {
    List<Contact> contacts = [];

    for (final tag in event.tags) {
      final length = tag.length;
      if (length < 2) continue;

      if (tag[0] == "p") {
        String url = "";
        String petname = "";
        if (length > 2) {
          url = tag[2];
          if (length > 3) {
            petname = tag[3];
          }
        }
        contacts.add(Contact(pubkey: tag[1], relay: url, petname: petname));
      }
    }
    return ContactList(event.pubkey, contacts, event: event);
  }

  final String pubkey;
  final List<Contact> contacts;
  Event? event;

  Future<Event> toEvent(final SignerFunction signer) async {
    Tags tags = [];
    for (final Contact contact in this.contacts) {
      final tag = ["p", contact.pubkey];
      if (contact.relay != null) tag.add(contact.relay!);
      if (contact.petname != null) tag.add(contact.petname!);
      tags.add(tag);
    }
    final event = await Event.finalizeWithSigner(signer, 3, tags, "");
    this.event = event;
    return event;
  }

  void add(final Contact contact) {
    if (this.contacts.indexWhere((c) => c.pubkey == contact.pubkey) == -1) {
      this.contacts.add(contact);
    }
  }

  Contact? get(final String pubkey) {
    return this.contacts.firstWhereOrNull((c) => c.pubkey == pubkey);
  }

  void remove(final String pubkey) {
    this.contacts.removeWhere((c) => c.pubkey == pubkey);
  }

  void clear() {
    this.contacts.clear();
  }
}

class Contact {
  Contact({required this.pubkey, this.relay, this.petname});

  final String pubkey;
  final String? relay;
  final String? petname;
}
