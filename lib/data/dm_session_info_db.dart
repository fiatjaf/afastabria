import 'package:loure/data/dm_session_info.dart';
import 'package:sqflite/sqflite.dart';

import 'package:loure/data/db.dart';

class DMSessionInfoDB {
  static Future<List<DMSessionInfo>> all(int keyIndex,
      {DatabaseExecutor? db}) async {
    db = DB.getDB(db);
    List<DMSessionInfo> l = [];
    List<dynamic> args = [keyIndex];

    var sql = "select * from dm_session_info where key_index = ?";

    List<Map<String, dynamic>> list = await db.rawQuery(sql, args);
    for (var listObj in list) {
      l.add(DMSessionInfo.fromJson(listObj));
    }
    return l;
  }

  static Future<int> insert(DMSessionInfo o, {DatabaseExecutor? db}) async {
    return await DB.getDB(db).insert("dm_session_info", o.toJson());
  }

  static Future<int> update(DMSessionInfo o, {DatabaseExecutor? db}) async {
    return await DB.getDB(db).update(
      "dm_session_info",
      o.toJson(),
      where: "key_index = ? and pubkey = ?",
      whereArgs: [o.keyIndex, o.pubkey],
    );
  }

  static Future<void> deleteAll(int keyIndex, {DatabaseExecutor? db}) async {
    DB
        .getDB(db)
        .execute("delete from dm_session_info where key_index = ?", [keyIndex]);
  }
}
