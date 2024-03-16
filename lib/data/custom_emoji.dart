class CustomEmoji {
  CustomEmoji(this.name, this.filepath);

  CustomEmoji.fromJson(final Map<String, dynamic> json) {
    name = json["name"];
    filepath = json["filepath"];
  }
  late String name;
  late String filepath;

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data["name"] = name;
    data["filepath"] = filepath;
    return data;
  }
}
