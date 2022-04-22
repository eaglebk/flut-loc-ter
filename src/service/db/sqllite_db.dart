import 'dart:io';

import 'package:logging/logging.dart';
import 'package:path/path.dart';
import 'package:sqlite3/sqlite3.dart';

import '../../model/extracted_string.dart';

class SQLiteDB {
  final log = Logger('SQLiteDB');
  Database? db;

  init() {
    log.info('Using sqlite3 ${sqlite3.version}');
    db = createDatabase();
  }

  Database createDatabase() {
    String databasesPath = Directory.current.path;
    String dbPath = join(databasesPath, 'strings.db');

    if (File(dbPath).existsSync()) {
      File(dbPath).deleteSync();
    }

    var database = sqlite3.open(dbPath);

    database.execute(
        'CREATE TABLE IF NOT EXISTS strings(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, context	TEXT,  file	TEXT NOT NULL, line_no INTEGER)');

    return database;
  }

  populateData(Set<ExtractedString>? data) {
    if (data?.isNotEmpty ?? false) {
      for (var d in data!) {
        final stmt =
            db?.prepare("INSERT INTO strings VALUES (NULL, ?, ?, ?, ?)");

        stmt?.execute([d.string, d.context, d.sourceFile, d.lineNumber]);
        stmt?.dispose();
      }
    }
  }
}
