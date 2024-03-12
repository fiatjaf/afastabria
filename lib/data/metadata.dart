class Metadata {
  String? pubKey;
  String? name;
  String? displayName;
  String? picture;
  String? banner;
  String? website;
  String? about;
  String? nip05;
  String? lud16;
  String? lud06;
  int? updated_at;
  int? valid;

  Metadata({
    this.pubKey,
    this.name,
    this.displayName,
    this.picture,
    this.banner,
    this.website,
    this.about,
    this.nip05,
    this.lud16,
    this.lud06,
    this.updated_at,
    this.valid,
  });

  Metadata.fromJson(Map<String, dynamic> json) {
    pubKey = json['pub_key'];
    name = json['name'];
    displayName = json['display_name'];
    picture = json['picture'];
    banner = json['banner'];
    website = json['website'];
    about = json['about'];
    nip05 = json['nip05'];
    lud16 = json['lud16'];
    lud06 = json['lud06'];
    if (json['updated_at'] != null && json['updated_at'] is int) {
      updated_at = json['updated_at'];
    }
    valid = json['valid'];
  }

  Map<String, dynamic> toFullJson() {
    var data = toJson();
    data['pub_key'] = pubKey;
    return data;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    data['display_name'] = displayName;
    data['picture'] = picture;
    data['banner'] = banner;
    data['website'] = website;
    data['about'] = about;
    data['nip05'] = nip05;
    data['lud16'] = lud16;
    data['lud06'] = lud06;
    data['updated_at'] = updated_at;
    data['valid'] = valid;
    return data;
  }
}
