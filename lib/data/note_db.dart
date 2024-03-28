import "dart:convert";

import "package:sqflite/sqflite.dart";

import "package:loure/client/event.dart";
import "package:loure/data/db.dart";

class NoteDB {
  static Future<void> insert(final Event event,
      {required bool isFollow, DatabaseExecutor? db}) async {
    db = DB.getDB(db);

    try {
      final rowid = await db.insert("note", {
        "id": event.id.substring(0, 16),
        "created_at": event.createdAt,
        "pubkey": event.pubkey.substring(0, 16),
        "follow": isFollow ? 1 : 0,
        "event": jsonEncode(event.toJson())
      });
      if (rowid != 0 && event.content.length > 50) {
        // we should replace pubkeys with names here, maybe in the future
        db.insert("note_content", {"rowid": rowid, "content": event.content});
      }
    } catch (err) {
      print("error inserting note: $err");
      /***/
    }
  }

  static Future<Event?> get(final String id, {DatabaseExecutor? db}) async {
    db = DB.getDB(db);
    final list = await db.query("note",
        columns: ["event"], where: "id = ?", whereArgs: [id.substring(0, 16)]);
    if (list.length > 0) {
      return Event.fromJson(jsonDecode(list[0]["event"] as String));
    }
    return null;
  }

  static Future<List<Event>> search(final String term,
      {DatabaseExecutor? db}) async {
    db = DB.getDB(db);
    final list = await db.rawQuery(
        "select event from note where rowid in (select rowid from note_content where content match ?)",
        [term]);
    return list
        .map((row) => Event.fromJson(jsonDecode(row["event"] as String)))
        .toList();
  }

  static Future<List<Event>> loadFromFollowing(
      {DatabaseExecutor? db, int limit = 200}) async {
    db = DB.getDB(db);
    final list = await db.query("note",
        columns: ["event"],
        where: "follow = true",
        orderBy: "created_at DESC",
        limit: limit);
    return list
        .map((row) => Event.fromJson(jsonDecode(row["event"] as String)))
        .toList();
  }
}
