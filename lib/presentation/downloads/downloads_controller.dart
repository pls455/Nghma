import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/sqlite_download_repository.dart';
import '../../data/services/download_manager.dart';
import '../../domain/entities/download_task.dart';

final downloadManagerProvider = Provider<DownloadManager>((ref) {
  return DownloadManager(repository: SqliteDownloadRepository());
});

final downloadsControllerProvider =
    AsyncNotifierProvider<DownloadsController, List<DownloadTask>>(
  DownloadsController.new,
);

class DownloadsController extends AsyncNotifier<List<DownloadTask>> {
  DownloadManager get _manager => ref.read(downloadManagerProvider);

  @override
  Future<List<DownloadTask>> build() => _manager.getTasks();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_manager.getTasks);
  }

  Future<void> pause(String id) async {
    await _manager.pause(id);
    await refresh();
  }

  Future<void> resume(String id) async {
    await _manager.resume(id);
    await refresh();
  }

  Future<void> cancel(String id) async {
    await _manager.cancel(id);
    await refresh();
  }
}
