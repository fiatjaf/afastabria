class ProfilePointer {
  const ProfilePointer(this.pubkey, this.relays);

  final String pubkey;
  final List<String> relays;
}

class EventPointer {
  const EventPointer(this.id, this.relays, this.author, this.kind);

  final String id;
  final List<String> relays;
  final String? author;
  final int? kind;
}

class AddressPointer {
  const AddressPointer(this.identifier, this.pubkey, this.kind, this.relays);

  final String identifier;
  final String pubkey;
  final int kind;
  final List<String> relays;
}
