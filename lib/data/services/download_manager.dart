import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';

import '../../domain/entities/download_task.dart';
import '../../domain/entities/media_item.dart';
import '../../domain/repositories/download_repository.dart';
import 'download_engine.dart';

class DownloadManager {
  DownloadManager({
    required DownloadRepository repository,
    DownloadEngine? engine,
    this.maxConcurrent = 2,
  }) : _repository = repository,
       _engine = engine ?? DownloadEngine();

  final DownloadRepository _repository;
  final DownloadEngine _engine;
  final int maxConcurrent;
  final Map<String, CancelToken> _tokens = {};
  final Set<String> _running = {};
  bool _pumping = false;

  Future<List<DownloadTask>> getTasks() => _repository.getAll();

  Future<String> enqueue({
    required MediaItem media,
    required String destinationPath,
  }) async {
    final now = DateTime.now();
    final id = '${now.microsecondsSinceEpoch}_${media.sourceUrl.hashCode}';
    final task = DownloadTask(
      id: id,
      media: media,
      destinationPath: destinationPath,
      status: DownloadStatus.queued,
      downloadedBytes: 0,
      totalBytes: media.sizeBytes,
      createdAt: now,
      updatedAt: now,
    );
    await _repository.upsert(task);
    unawaited(_pump());
    return id;
  }

  Future<void> pause(String id) async {
    final token = _tokens[id];
    token?.cancel('paused');
    final task = await _repository.getById(id);
    if (task == null) return;
    await _repository.upsert(
      task.copyWith(
        status: DownloadStatus.paused,
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<void> resume(String id) async {
    final task = await _repository.getById(id);
    if (task == null) return;
    if (task.status != DownloadStatus.paused &&
        task.status != DownloadStatus.failed) {
      return;
    }
    await _repository.upsert(
      task.copyWith(
        status: DownloadStatus.queued,
        updatedAt: DateTime.now(),
        clearError: true,
      ),
    );
    unawaited(_pump());
  }

  Future<void> retry(String id) => resume(id);

  Future<void> cancel(String id) async {
    _tokens[id]?.cancel('cancelled');
    final task = await _repository.getById(id);
    if (task == null) return;

    final partFile = File('${task.destinationPath}.part');
    if (await partFile.exists()) {
      await partFile.delete();
    }

    await _repository.upsert(
      task.copyWith(
        status: DownloadStatus.cancelled,
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<void> _pump() async {
    if (_pumping) return;
    _pumping = true;
    try {
      while (_running.length < maxConcurrent) {
        final tasks = await _repository.getAll();
        final queued = tasks.where(
          (task) => task.status == DownloadStatus.queued,
        );
        final next = queued.firstWhere(
          (task) => !_running.contains(task.id),
          orElse: () => throw StateError('no queued task'),
        );
        _running.add(next.id);
        unawaited(_run(next));
      }
    } on StateError {
      // Queue is empty. Nothing to schedule.
    } finally {
      _pumping = false;
    }
  }

  Future<void> _run(DownloadTask task) async {
    final token = CancelToken();
    _tokens[task.id] = token;
    try {
      final partPath = '${task.destinationPath}.part';
      final existing = File(partPath);
      final existingBytes = await existing.exists() ? await existing.length() : 0;

      await _repository.upsert(
        task.copyWith(
          status: DownloadStatus.downloading,
          downloadedBytes: existingBytes,
          updatedAt: DateTime.now(),
        ),
      );

      final result = await _engine.download(
        url: task.media.sourceUrl,
        partPath: partPath,
        cancelToken: token,
        onProgress: (downloaded, total, speed) async {
          final current = await _repository.getById(task.id);
          if (current == null) return;
          await _repository.upsert(
            current.copyWith(
              status: DownloadStatus.downloading,
              downloadedBytes: downloaded,
              totalBytes: total,
              speedBytesPerSecond: speed,
              updatedAt: DateTime.now(),
            ),
          );
        },
      );

      final destination = File(task.destinationPath);
      final part = File(partPath);
      if (await destination.exists()) {
        await destination.delete();
      }
      await part.rename(destination.path);

      final current = await _repository.getById(task.id);
      if (current != null) {
        await _repository.upsert(
          current.copyWith(
            status: DownloadStatus.completed,
            downloadedBytes: result.downloadedBytes,
            totalBytes: result.totalBytes ?? current.totalBytes,
            speedBytesPerSecond: 0,
            updatedAt: DateTime.now(),
          ),
        );
      }
    } on DioException catch (error) {
      final current = await _repository.getById(task.id);
      if (current != null) {
        final cancelled = error.type == DioExceptionType.cancel;
        await _repository.upsert(
          current.copyWith(
            status: cancelled ? DownloadStatus.paused : DownloadStatus.failed,
            speedBytesPerSecond: 0,
            updatedAt: DateTime.now(),
            errorMessage: cancelled ? null : _friendlyError(error),
          ),
        );
      }
    } catch (error) {
      final current = await _repository.getById(task.id);
      if (current != null) {
        await _repository.upsert(
          current.copyWith(
            status: DownloadStatus.failed,
            speedBytesPerSecond: 0,
            updatedAt: DateTime.now(),
            errorMessage: error.toString(),
          ),
        );
      }
    } finally {
      _tokens.remove(task.id);
      _running.remove(task.id);
      unawaited(_pump());
    }
  }

  String _friendlyError(DioException error) {
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return 'تعذر الاتصال بالمصدر. تحقق من الإنترنت وحاول مرة أخرى.';
    }
    return 'فشل التنزيل. حاول مرة أخرى.';
  }
}
