import "dart:convert";

import "package:sqflite/sqflite.dart";

import "package:loure/client/event.dart";
import "package:loure/client/nip02/contact_list.dart";
import "package:loure/data/db.dart";

class ContactListDB {
  static Future<List<ContactList>> all({final DatabaseExecutor? db}) async {
    List<ContactList> objs = [];

    List<Map<String, dynamic>> list =
        await DB.getDB(null).rawQuery("select event from contactlist");
    for (var i = 0; i < list.length; i++) {
      final json = list[i];
      objs.add(ContactList.fromEvent(
          Event.fromJson(jsonDecode(json["event"] as String))));
    }
    return objs;
  }

  static Future<ContactList?> get(final String pubKey,
      {final DatabaseExecutor? db}) async {
    final list = await DB.getDB(db).query("contactlist",
        columns: ["event"],
        where: "pubkey = ?",
        whereArgs: [pubKey.substring(0, 16)]);

    if (list.length > 0) {
      return ContactList.fromEvent(
          Event.fromJson(jsonDecode(list[0]["event"] as String)));
    }
    return null;
  }

  static Future<Iterable<ContactList>> search(final String term,
      {final DatabaseExecutor? db}) async {
    final list = await DB.getDB(db).query("contactlist",
        where: "event like '%' || ? || '%' LIMIT 7", whereArgs: [term]);

    return list.map((final row) => ContactList.fromEvent(
        Event.fromJson(jsonDecode(row["event"] as String))));
  }

  static Future<int> insert(final ContactList o,
      {final DatabaseExecutor? db}) async {
    return await DB.getDB(db).insert("contactlist", {
      "pubkey": o.pubkey.substring(0, 16),
      "event": jsonEncode(o.event!.toJson()),
    });
  }

  static Future update(final ContactList o,
      {final DatabaseExecutor? db}) async {
    await DB.getDB(db).update(
        "contactlist", {"event": jsonEncode(o.event!.toJson())},
        where: "pubkey = ?", whereArgs: [o.pubkey.substring(0, 16)]);
  }

  static Future upsert(final ContactList o,
      {final DatabaseExecutor? db}) async {
    return await DB.getDB(db).execute(
        "insert into contactlist (pubkey, event) values (?, ?) on conflict (pubkey) do update set event = excluded.event",
        [o.pubkey.substring(0, 16), jsonEncode(o.event!.toJson())]);
  }

  static Future<void> delete(final String pubkey,
      {final DatabaseExecutor? db}) async {
    DB.getDB(db).execute(
        "delete from contactlist where pubkey = ?", [pubkey.substring(0, 16)]);
  }

  static Future<void> deleteAll({final DatabaseExecutor? db}) async {
    DB.getDB(db).execute("delete from contactlist");
  }
}
