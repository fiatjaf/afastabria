import "dart:convert";

import "package:sqflite/sqflite.dart";

import "package:loure/client/event.dart";
import "package:loure/client/nip65/relay_list.dart";
import "package:loure/data/db.dart";

class RelayListDB {
  static Future<List<RelayList>> all({final DatabaseExecutor? db}) async {
    List<RelayList> objs = [];

    List<Map<String, dynamic>> list =
        await DB.getDB(null).rawQuery("select * from relaylist");
    for (var i = 0; i < list.length; i++) {
      final json = list[i];
      objs.add(RelayList.fromEvent(
          Event.fromJson(jsonDecode(json["event"] as String))));
    }
    return objs;
  }

  static Future<RelayList?> get(final String pubkey,
      {final DatabaseExecutor? db}) async {
    final list = await DB
        .getDB(db)
        .query("relaylist", where: "pubkey = ?", whereArgs: [pubkey]);

    if (list.length > 0) {
      return RelayList.fromEvent(
          Event.fromJson(jsonDecode(list[0]["event"] as String)));
    }
    return null;
  }

  static Future insert(final RelayList o, {final DatabaseExecutor? db}) async {
    if (o.event == null) return;

    return await DB.getDB(db).insert("relaylist",
        {"pubkey": o.event!.pubkey, "event": jsonEncode(o.event!.toJson())});
  }

  static Future update(final RelayList o, {final DatabaseExecutor? db}) async {
    if (o.event == null) return;

    await DB.getDB(db).update(
        "relaylist", {"event": jsonEncode(o.event!.toJson())},
        where: "pubkey = ?", whereArgs: [o.event!.pubkey]);
  }

  static Future upsert(final RelayList o, {final DatabaseExecutor? db}) async {
    if (o.event == null) return;

    return await DB.getDB(db).execute(
        "insert into relaylist (pubkey, event) values (?, ?) on conflict (pubkey) do update set event = excluded.event",
        [o.event!.pubkey, jsonEncode(o.event!.toJson())]);
  }

  static Future<void> delete(final String pubkey,
      {final DatabaseExecutor? db}) async {
    DB.getDB(db).execute("delete from relaylist where pubkey = ?", [pubkey]);
  }

  static Future<void> deleteAll({final DatabaseExecutor? db}) async {
    DB.getDB(db).execute("delete from relaylist");
  }
}
