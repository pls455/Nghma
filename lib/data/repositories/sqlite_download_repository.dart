import 'package:sqflite/sqflite.dart';

import '../../domain/entities/download_task.dart';
import '../../domain/entities/media_item.dart';
import '../../domain/repositories/download_repository.dart';
import '../database/download_database.dart';

class SqliteDownloadRepository implements DownloadRepository {
  SqliteDownloadRepository({DownloadDatabase? database})
      : _database = database ?? DownloadDatabase.instance;

  final DownloadDatabase _database;

  @override
  Future<List<DownloadTask>> getAll() async {
    final db = await _database.database;
    final rows = await db.query('downloads', orderBy: 'created_at DESC');
    return rows.map(_fromRow).toList(growable: false);
  }

  @override
  Future<DownloadTask?> getById(String id) async {
    final db = await _database.database;
    final rows = await db.query(
      'downloads',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _fromRow(rows.first);
  }

  @override
  Future<void> upsert(DownloadTask task) async {
    final db = await _database.database;
    await db.insert(
      'downloads',
      _toRow(task),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> delete(String id) async {
    final db = await _database.database;
    await db.delete('downloads', where: 'id = ?', whereArgs: [id]);
  }

  Map<String, Object?> _toRow(DownloadTask task) {
    return {
      'id': task.id,
      'title': task.media.title,
      'source_url': task.media.sourceUrl,
      'mime_type': task.media.mimeType,
      'duration_ms': task.media.duration?.inMilliseconds,
      'size_bytes': task.media.sizeBytes,
      'thumbnail_url': task.media.thumbnailUrl,
      'destination_path': task.destinationPath,
      'status': task.status.name,
      'downloaded_bytes': task.downloadedBytes,
      'total_bytes': task.totalBytes,
      'speed_bytes_per_second': task.speedBytesPerSecond,
      'created_at': task.createdAt.toIso8601String(),
      'updated_at': task.updatedAt.toIso8601String(),
      'error_message': task.errorMessage,
    };
  }

  DownloadTask _fromRow(Map<String, Object?> row) {
    final durationMs = row['duration_ms'] as int?;
    final statusName = row['status']! as String;
    final status = DownloadStatus.values.firstWhere(
      (value) => value.name == statusName,
      orElse: () => DownloadStatus.failed,
    );

    return DownloadTask(
      id: row['id']! as String,
      media: MediaItem(
        id: row['source_url']! as String,
        title: row['title']! as String,
        sourceUrl: row['source_url']! as String,
        mimeType: row['mime_type'] as String?,
        duration:
            durationMs == null ? null : Duration(milliseconds: durationMs),
        sizeBytes: row['size_bytes'] as int?,
        thumbnailUrl: row['thumbnail_url'] as String?,
      ),
      destinationPath: row['destination_path']! as String,
      status: status,
      downloadedBytes: row['downloaded_bytes']! as int,
      totalBytes: row['total_bytes'] as int?,
      speedBytesPerSecond: row['speed_bytes_per_second']! as int,
      createdAt: DateTime.parse(row['created_at']! as String),
      updatedAt: DateTime.parse(row['updated_at']! as String),
      errorMessage: row['error_message'] as String?,
    );
  }
}
