import "dart:convert";

import "package:loure/client/event.dart";
import "package:loure/data/metadata.dart";
import "package:sqflite/sqflite.dart";

import "package:loure/data/db.dart";

class MetadataDB {
  static Future<List<Metadata>> all({final DatabaseExecutor? db}) async {
    List<Metadata> objs = [];

    List<Map<String, dynamic>> list =
        await DB.getDB(null).rawQuery("select * from metadata");
    for (var i = 0; i < list.length; i++) {
      final json = list[i];
      objs.add(Metadata.fromEvent(
          Event.fromJson(jsonDecode(json["event"] as String))));
    }
    return objs;
  }

  static Future<Metadata?> get(final String pubKey,
      {final DatabaseExecutor? db}) async {
    final list = await DB
        .getDB(db)
        .query("metadata", where: "pubkey = ?", whereArgs: [pubKey]);

    if (list.length > 0) {
      return Metadata.fromEvent(
          Event.fromJson(jsonDecode(list[0]["event"] as String)));
    }
    return null;
  }

  static Future<Iterable<Metadata>> search(final String term,
      {final DatabaseExecutor? db}) async {
    final list = await DB.getDB(db).query("metadata",
        where: "event like '%' || ? || '%' LIMIT 7", whereArgs: [term]);

    return list.map((final row) =>
        Metadata.fromEvent(Event.fromJson(jsonDecode(row["event"] as String))));
  }

  static Future<int> insert(final Metadata o,
      {final DatabaseExecutor? db}) async {
    return await DB.getDB(db).insert("metadata",
        {"pubkey": o.pubkey, "event": jsonEncode(o.event!.toJson())});
  }

  static Future update(final Metadata o, {final DatabaseExecutor? db}) async {
    await DB.getDB(db).update(
        "metadata", {"event": jsonEncode(o.event!.toJson())},
        where: "pubkey = ?", whereArgs: [o.pubkey]);
  }

  static Future<void> delete(final String pubkey,
      {final DatabaseExecutor? db}) async {
    DB.getDB(db).execute("delete from metadata where pubkey = ?", [pubkey]);
  }

  static Future<void> deleteAll({final DatabaseExecutor? db}) async {
    DB.getDB(db).execute("delete from metadata");
  }
}
