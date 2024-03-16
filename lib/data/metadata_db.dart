import 'dart:convert';

import 'package:loure/client/event.dart';
import 'package:loure/data/metadata.dart';
import 'package:sqflite/sqflite.dart';

import 'package:loure/data/db.dart';

class MetadataDB {
  static Future<List<Metadata>> all({DatabaseExecutor? db}) async {
    List<Metadata> objs = [];
    Database db = await DB.getCurrentDatabase();

    List<Map<String, dynamic>> list =
        await db.rawQuery("select * from metadata");
    for (var i = 0; i < list.length; i++) {
      var json = list[i];
      objs.add(Metadata.fromEvent(
          Event.fromJson(jsonDecode(json['event'] as String))));
    }
    return objs;
  }

  static Future<Metadata?> get(String pubKey, {DatabaseExecutor? db}) async {
    db = await DB.getDB(db);

    var list =
        await db.query("metadata", where: "pubkey = ?", whereArgs: [pubKey]);

    if (list.length > 0) {
      return Metadata.fromEvent(
          Event.fromJson(jsonDecode(list[0]['event'] as String)));
    }
    return null;
  }

  static Future<Iterable<Metadata>> search(String term,
      {DatabaseExecutor? db}) async {
    db = await DB.getDB(db);

    var list = await db.query("metadata",
        where: "event like '%' || ? || '%' LIMIT 7", whereArgs: [term]);

    return list.map((row) => Metadata.fromEvent(
        Event.fromJson(jsonDecode((row['event'] as String)))));
  }

  static Future<int> insert(Metadata o, {DatabaseExecutor? db}) async {
    db = await DB.getDB(db);
    return await db.insert("metadata",
        {"pubkey": o.pubkey, "event": jsonEncode(o.event!.toJson())});
  }

  static Future update(Metadata o, {DatabaseExecutor? db}) async {
    db = await DB.getDB(db);
    await db.update("metadata", {'event': jsonEncode(o.event!.toJson())},
        where: "pubkey = ?", whereArgs: [o.pubkey]);
  }

  static Future<void> delete(String pubkey, {DatabaseExecutor? db}) async {
    db = await DB.getDB(db);
    db.execute("delete from metadata where pubkey = ?", [pubkey]);
  }

  static Future<void> deleteAll({DatabaseExecutor? db}) async {
    db = await DB.getDB(db);
    db.execute("delete from metadata");
  }
}
