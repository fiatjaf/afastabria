/// filter is a JSON object that determines what events will be sent in that subscription
class Filter {
  /// a list of event ids or prefixes
  List<String>? ids;

  /// a list of pubkeys or prefixes, the pubkey of an event must be one of these
  List<String>? authors;

  /// a list of a kind numbers
  List<int>? kinds;

  /// a list of event ids that are referenced in an "e" tag
  List<String>? e;

  /// a list of pubkeys that are referenced in a "p" tag
  List<String>? p;

  /// a timestamp, events must be newer than this to pass
  int? since;

  /// a timestamp, events must be older than this to pass
  int? until;

  /// maximum number of events to be returned in the initial query
  int? limit;

  // NIP-50 optional fulltext search
  String? search;

  /// Default constructor
  Filter({
    this.ids,
    this.authors,
    this.kinds,
    this.e,
    this.p,
    this.since,
    this.until,
    this.limit,
    this.search,
  });

  /// Deserialize a filter from a JSON
  Filter.fromJson(Map<String, dynamic> json) {
    this.ids = json['ids'] == null ? null : List<String>.from(json['ids']);
    this.authors =
        json['authors'] == null ? null : List<String>.from(json['authors']);
    this.kinds = json['kinds'] == null ? null : List<int>.from(json['kinds']);
    this.e = json['#e'] == null ? null : List<String>.from(json['#e']);
    this.p = json['#p'] == null ? null : List<String>.from(json['#p']);
    this.since = json['since'];
    this.until = json['until'];
    this.limit = json['limit'];
    this.search = json['search'];
  }

  /// Serialize a filter in JSON
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (this.ids != null) {
      data['ids'] = this.ids;
    }
    if (this.authors != null) {
      data['authors'] = this.authors;
    }
    if (this.kinds != null) {
      data['kinds'] = this.kinds;
    }
    if (this.e != null) {
      data['#e'] = this.e;
    }
    if (this.p != null) {
      data['#p'] = this.p;
    }
    if (this.since != null) {
      data['since'] = this.since;
    }
    if (this.until != null) {
      data['until'] = this.until;
    }
    if (this.limit != null) {
      data['limit'] = this.limit;
    }
    if (this.search != null) {
      data['search'] = this.search;
    }
    return data;
  }

  Filter clone() {
    return Filter(this.ids, this.authors, this.kinds, this.e, this.p,
        this.since, this.until, this.limit, this.search);
  }
}
