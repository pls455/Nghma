import '../entities/download_task.dart';

abstract interface class DownloadRepository {
  Future<List<DownloadTask>> getAll();

  Future<DownloadTask?> getById(String id);

  Future<void> upsert(DownloadTask task);

  Future<void> delete(String id);
}
