/// filter is a JSON object that determines what events will be sent in that subscription
class Filter {
  /// Default constructor
  Filter({
    this.ids,
    this.authors,
    this.kinds,
    this.e,
    this.p,
    this.a,
    this.d,
    this.t,
    this.since,
    this.until,
    this.limit,
    this.search,
  });

  /// Deserialize a filter from a JSON
  Filter.fromJson(final Map<String, dynamic> json) {
    this.ids = json["ids"] == null ? null : List<String>.from(json["ids"]);
    this.authors =
        json["authors"] == null ? null : List<String>.from(json["authors"]);
    this.kinds = json["kinds"] == null ? null : List<int>.from(json["kinds"]);
    this.e = json["#e"] == null ? null : List<String>.from(json["#e"]);
    this.p = json["#p"] == null ? null : List<String>.from(json["#p"]);
    this.a = json["#a"] == null ? null : List<String>.from(json["#a"]);
    this.d = json["#d"] == null ? null : List<String>.from(json["#d"]);
    this.t = json["#t"] == null ? null : List<String>.from(json["#t"]);
    this.since = json["since"];
    this.until = json["until"];
    this.limit = json["limit"];
    this.search = json["search"];
  }

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

  /// a list of addresses that are referenced in a "a" tag
  List<String>? a;

  /// a list of identifiers that are referenced in a "d" tag
  List<String>? d;

  /// a list of hashtags that are referenced in a "t" tag
  List<String>? t;

  /// a timestamp, events must be newer than this to pass
  int? since;

  /// a timestamp, events must be older than this to pass
  int? until;

  /// maximum number of events to be returned in the initial query
  int? limit;

  // NIP-50 optional fulltext search
  String? search;

  /// Serialize a filter in JSON
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (this.ids != null) {
      data["ids"] = this.ids;
    }
    if (this.authors != null) {
      data["authors"] = this.authors;
    }
    if (this.kinds != null) {
      data["kinds"] = this.kinds;
    }
    if (this.e != null) {
      data["#e"] = this.e;
    }
    if (this.p != null) {
      data["#p"] = this.p;
    }
    if (this.a != null) {
      data["#a"] = this.a;
    }
    if (this.d != null) {
      data["#d"] = this.d;
    }
    if (this.t != null) {
      data["#t"] = this.t;
    }
    if (this.since != null) {
      data["since"] = this.since;
    }
    if (this.until != null) {
      data["until"] = this.until;
    }
    if (this.limit != null) {
      data["limit"] = this.limit;
    }
    if (this.search != null) {
      data["search"] = this.search;
    }
    return data;
  }

  Filter clone() {
    return Filter(
      ids: this.ids,
      authors: this.authors,
      kinds: this.kinds,
      e: this.e,
      p: this.p,
      a: this.a,
      d: this.d,
      t: this.t,
      since: this.since,
      until: this.until,
      limit: this.limit,
      search: this.search,
    );
  }
}
