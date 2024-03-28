import "dart:convert";

import "package:sqflite_common_ffi/sqflite_ffi.dart";
import "package:sqflite/sqflite.dart";

import "package:loure/data/db.dart";
import "package:loure/client/replaceable_loader.dart";

class ReplaceableDB<K extends Replaceable> {
  ReplaceableDB(this.dbname, this.readFromRow);

  final String dbname;
  final K Function(Map<String, dynamic>) readFromRow;

  Future<List<K>> all({final DatabaseExecutor? db}) async {
    List<K> objs = [];

    List<Map<String, dynamic>> list =
        await DB.getDB(null).rawQuery("select event from ${this.dbname}");
    for (var i = 0; i < list.length; i++) {
      final json = list[i];
      objs.add(this.readFromRow(json["event"]));
    }
    return objs;
  }

  Future<K?> get(final String pubkey, {final DatabaseExecutor? db}) async {
    final list = await DB.getDB(db).query(this.dbname,
        columns: ["event"],
        where: "pubkey = ?",
        whereArgs: [pubkey.substring(0, 16)]);

    if (list.length > 0) {
      return this.readFromRow(list[0]);
    }
    return null;
  }

  Future<List<K>> batchGet(final Iterable<String> pubkeys,
      {final DatabaseExecutor? db}) async {
    final args = pubkeys.map((pk) => pk.substring(0, 16)).toList();
    final list = await DB.getDB(db).query(
          this.dbname,
          columns: ["event", "stored_at"],
          where: "pubkey in (${(",?" * args.length).substring(1)})",
          whereArgs: args,
        );

    return list.map(readFromRow).toList();
  }

  Future<int> insert(final K o, {final DatabaseExecutor? db}) async {
    return await DB.getDB(db).insert(this.dbname, {
      "pubkey": o.pubkey.substring(0, 16),
      "event": jsonEncode(o.event!.toJson()),
      "stored_at": DateTime.now().millisecondsSinceEpoch ~/ 1000,
    });
  }

  Future update(final K o, {final DatabaseExecutor? db}) async {
    await DB.getDB(db).update(
        this.dbname, {"event": jsonEncode(o.event!.toJson())},
        where: "pubkey = ?", whereArgs: [o.pubkey.substring(0, 16)]);
  }

  Future upsert(final K o, {final DatabaseExecutor? db}) async {
    return await DB.getDB(db).execute(
        "insert into ${this.dbname} (pubkey, event, stored_at) values (?, ?, strftime('%s', 'now')) on conflict (pubkey) do update set event = excluded.event, stored_at = excluded.stored_at",
        [o.pubkey.substring(0, 16), jsonEncode(o.event!.toJson())]);
  }

  Future<void> delete(final String pubkey, {final DatabaseExecutor? db}) async {
    DB.getDB(db).execute("delete from ${this.dbname} where pubkey = ?",
        [pubkey.substring(0, 16)]);
  }

  Future<void> deleteAll({final DatabaseExecutor? db}) async {
    DB.getDB(db).execute("delete from ${this.dbname}");
  }
}
