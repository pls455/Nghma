import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

class DownloadDatabase {
  DownloadDatabase._();

  static final DownloadDatabase instance = DownloadDatabase._();
  Database? _database;

  Future<Database> get database async {
    final current = _database;
    if (current != null) return current;

    final databasesPath = await getDatabasesPath();
    final dbPath = path.join(databasesPath, 'naghama.db');
    final database = await openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE downloads (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            source_url TEXT NOT NULL,
            mime_type TEXT,
            duration_ms INTEGER,
            size_bytes INTEGER,
            thumbnail_url TEXT,
            destination_path TEXT NOT NULL,
            status TEXT NOT NULL,
            downloaded_bytes INTEGER NOT NULL,
            total_bytes INTEGER,
            speed_bytes_per_second INTEGER NOT NULL,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            error_message TEXT
          )
        ''');
      },
    );
    _database = database;
    return database;
  }
}
