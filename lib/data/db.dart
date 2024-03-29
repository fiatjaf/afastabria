import "package:sqflite/sqflite.dart";
import "package:path/path.dart";

import "package:loure/util/platform_util.dart";

class DB {
  static const _VERSION = 1;
  static const _dbName = "loure.db";

  static Database? _database;

  static init() async {
    String path = _dbName;

    if (!PlatformUtil.isWeb()) {
      final databasesPath = await getDatabasesPath();
      path = join(databasesPath, _dbName);
    }

    _database = await openDatabase(path, version: _VERSION,
        onCreate: (final Database db, final int version) async {
      // init db

      // replaceable tables
      db.execute(
          "create table metadata(pubkey text not null primary key, event text not null, stored_at int not null);");
      db.execute(
          "create table relaylist(pubkey text not null primary key, event text not null, stored_at int not null);");
      db.execute(
          "create table contactlist(pubkey text not null primary key, event text not null, stored_at int not null);");

      // notes
      db.execute(
          "create table note(id text not null primary key, pubkey not null, created_at integer not null, follow bool not null, event text not null);");
      db.execute(
          "create index note_follow_created_at on note (follow, created_at);");
      db.execute(
          "create index note_pubkey_created_at on note (pubkey, created_at);");

      // fulltext search
      db.execute(
          "create virtual table note_content using fts4(rowid int, content text, tokenize=porter);");

      // legacy: delete
      db.execute(
          "create table event(key_index INTEGER, id text, pubkey text, created_at integer, kind integer, tags text, content text);");
      db.execute(
          "create unique index event_key_index_id_uindex on event (key_index, id);");
      db.execute(
          "create index event_date_index on event (key_index, kind, created_at);");
      db.execute(
          "create index event_pubkey_index on event (key_index, kind, pubkey, created_at);");
      db.execute(
          "create table dm_session_info(key_index INTEGER, pubkey text not null, readed_time integer not null, value1 text, value2 text, value3 text);");
      db.execute(
          "create unique index dm_session_info_uindex on dm_session_info (key_index, pubkey);");
    });
  }

  static DatabaseExecutor getDB(final DatabaseExecutor? db) {
    if (db != null) {
      return db;
    }
    return _database!;
  }

  static Future transaction(Future Function(Transaction) action,
      {bool? exclusive}) async {
    await _database!.transaction(action, exclusive: exclusive);
  }

  static void close() {
    _database?.close();
    _database = null;
  }
}
