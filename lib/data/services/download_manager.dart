import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';

import '../../domain/entities/download_task.dart';
import '../../domain/entities/media_item.dart';
import '../../domain/repositories/download_repository.dart';
import 'download_engine.dart';
import 'media_muxer.dart';

class DownloadManager {
  DownloadManager({
    required DownloadRepository repository,
    DownloadEngine? engine,
    MediaMuxer? muxer,
    this.maxConcurrent = 2,
  })  : _repository = repository,
        _engine = engine ?? DownloadEngine(),
        _muxer = muxer ?? const MediaMuxer();

  final DownloadRepository _repository;
  final DownloadEngine _engine;
  final MediaMuxer _muxer;
  final int maxConcurrent;
  final Map<String, CancelToken> _tokens = {};
  final Set<String> _running = {};
  bool _pumping = false;

  Future<List<DownloadTask>> getTasks() => _repository.getAll();

  Future<String> enqueue({
    required MediaItem media,
    required String destinationPath,
    String? secondarySourceUrl,
    int? secondarySizeBytes,
  }) async {
    final existing = await _repository.getAll();
    final duplicate = existing.where((task) {
      final samePrimary = task.media.sourceUrl == media.sourceUrl;
      final sameSecondary = task.secondarySourceUrl == secondarySourceUrl;
      return samePrimary && sameSecondary && task.status != DownloadStatus.cancelled;
    }).firstOrNull;
    if (duplicate != null) {
      if (duplicate.status == DownloadStatus.failed || duplicate.status == DownloadStatus.paused) {
        await resume(duplicate.id);
      }
      return duplicate.id;
    }

    final now = DateTime.now();
    final id = '${now.microsecondsSinceEpoch}_${media.sourceUrl.hashCode}';
    final total = media.sizeBytes != null && secondarySizeBytes != null
        ? media.sizeBytes! + secondarySizeBytes
        : media.sizeBytes;
    await _repository.upsert(DownloadTask(
      id: id,
      media: media,
      destinationPath: destinationPath,
      status: DownloadStatus.queued,
      downloadedBytes: 0,
      totalBytes: total,
      secondarySourceUrl: secondarySourceUrl,
      secondarySizeBytes: secondarySizeBytes,
      createdAt: now,
      updatedAt: now,
    ));
    unawaited(_pump());
    return id;
  }

  Future<void> pause(String id) async {
    final task = await _repository.getById(id);
    if (task == null ||
        (task.status != DownloadStatus.downloading && task.status != DownloadStatus.queued)) {
      return;
    }
    _tokens[id]?.cancel('paused');
    await _repository.upsert(task.copyWith(
      status: DownloadStatus.paused,
      speedBytesPerSecond: 0,
      updatedAt: DateTime.now(),
    ));
  }

  Future<void> resume(String id) async {
    final task = await _repository.getById(id);
    if (task == null ||
        (task.status != DownloadStatus.paused && task.status != DownloadStatus.failed)) {
      return;
    }
    await _repository.upsert(task.copyWith(
      status: DownloadStatus.queued,
      speedBytesPerSecond: 0,
      updatedAt: DateTime.now(),
      clearError: true,
    ));
    unawaited(_pump());
  }

  Future<void> retry(String id) => resume(id);

  Future<void> cancel(String id) async {
    _tokens[id]?.cancel('cancelled');
    final task = await _repository.getById(id);
    if (task == null) return;
    for (final suffix in const ['.part', '.video.part', '.audio.part']) {
      final file = File('${task.destinationPath}$suffix');
      if (await file.exists()) await file.delete();
    }
    await _repository.upsert(task.copyWith(
      status: DownloadStatus.cancelled,
      downloadedBytes: 0,
      speedBytesPerSecond: 0,
      updatedAt: DateTime.now(),
    ));
  }

  Future<void> _pump() async {
    if (_pumping) return;
    _pumping = true;
    try {
      while (_running.length < maxConcurrent) {
        final tasks = await _repository.getAll();
        final next = tasks.where((task) =>
            task.status == DownloadStatus.queued && !_running.contains(task.id)).firstOrNull;
        if (next == null) break;
        _running.add(next.id);
        unawaited(_run(next));
      }
    } finally {
      _pumping = false;
    }
  }

  Future<void> _run(DownloadTask task) async {
    final token = CancelToken();
    _tokens[task.id] = token;
    try {
      if (task.requiresMuxing) {
        await _runMuxed(task, token);
      } else {
        await _runSingle(task, token);
      }
    } on DioException catch (error) {
      await _markFailure(
        task.id,
        error.type == DioExceptionType.cancel ? null : _friendlyError(error),
        paused: error.type == DioExceptionType.cancel,
      );
    } on DownloadEngineException catch (error) {
      await _markFailure(task.id, error.message);
    } on MediaMuxerException catch (error) {
      await _markFailure(task.id, error.message);
    } catch (_) {
      await _markFailure(task.id, 'حدث خطأ أثناء التنزيل. حاول مرة أخرى.');
    } finally {
      _tokens.remove(task.id);
      _running.remove(task.id);
      unawaited(_pump());
    }
  }

  Future<void> _runSingle(DownloadTask task, CancelToken token) async {
    final partPath = '${task.destinationPath}.part';
    await _setDownloading(task);
    final result = await _engine.download(
      url: task.media.sourceUrl,
      partPath: partPath,
      cancelToken: token,
      onProgress: (downloaded, total, speed) {
        unawaited(_updateProgress(task.id, downloaded, total, speed));
      },
    );
    await _complete(task, partPath, result.downloadedBytes,
        result.totalBytes ?? task.totalBytes);
  }

  Future<void> _runMuxed(DownloadTask task, CancelToken token) async {
    final videoPart = '${task.destinationPath}.video.part';
    final audioPart = '${task.destinationPath}.audio.part';
    var videoDownloaded = await _fileLength(videoPart);
    var audioDownloaded = await _fileLength(audioPart);
    await _setDownloading(task);

    final videoResult = await _engine.download(
      url: task.media.sourceUrl,
      partPath: videoPart,
      cancelToken: token,
      onProgress: (downloaded, total, speed) {
        videoDownloaded = downloaded;
        unawaited(_updateProgress(
          task.id,
          videoDownloaded + audioDownloaded,
          task.totalBytes ?? (total == null ? null : total + (task.secondarySizeBytes ?? 0)),
          speed,
        ));
      },
    );
    videoDownloaded = videoResult.downloadedBytes;

    final audioResult = await _engine.download(
      url: task.secondarySourceUrl!,
      partPath: audioPart,
      cancelToken: token,
      onProgress: (downloaded, total, speed) {
        audioDownloaded = downloaded;
        unawaited(_updateProgress(
          task.id,
          videoDownloaded + audioDownloaded,
          task.totalBytes ?? (total == null ? null : total + videoDownloaded),
          speed,
        ));
      },
    );
    audioDownloaded = audioResult.downloadedBytes;

    if (token.isCancelled) {
      throw DioException.requestCancelled(
        requestOptions: RequestOptions(path: task.secondarySourceUrl!),
        reason: 'تم إيقاف التنزيل.',
      );
    }

    await _muxer.mux(
      videoPath: videoPart,
      audioPath: audioPart,
      outputPath: task.destinationPath,
    );
    await File(videoPart).delete();
    await File(audioPart).delete();

    final current = await _repository.getById(task.id);
    if (current == null || current.status == DownloadStatus.cancelled) return;
    await _repository.upsert(current.copyWith(
      status: DownloadStatus.completed,
      downloadedBytes: videoDownloaded + audioDownloaded,
      totalBytes: task.totalBytes,
      speedBytesPerSecond: 0,
      updatedAt: DateTime.now(),
      clearError: true,
    ));
  }

  Future<void> _setDownloading(DownloadTask task) async {
    await _repository.upsert(task.copyWith(
      status: DownloadStatus.downloading,
      updatedAt: DateTime.now(),
    ));
  }

  Future<void> _updateProgress(
      String id, int downloaded, int? total, int speed) async {
    final current = await _repository.getById(id);
    if (current == null || current.status == DownloadStatus.cancelled) return;
    await _repository.upsert(current.copyWith(
      status: DownloadStatus.downloading,
      downloadedBytes: downloaded,
      totalBytes: total ?? current.totalBytes,
      speedBytesPerSecond: speed,
      updatedAt: DateTime.now(),
    ));
  }

  Future<void> _complete(
      DownloadTask task, String partPath, int downloaded, int? total) async {
    final current = await _repository.getById(task.id);
    if (current == null || current.status == DownloadStatus.cancelled) return;
    final destination = File(task.destinationPath);
    final part = File(partPath);
    if (!await part.exists()) {
      throw const DownloadEngineException('ملف التنزيل المؤقت غير موجود.');
    }
    if (await destination.exists()) await destination.delete();
    await part.rename(destination.path);
    await _repository.upsert(current.copyWith(
      status: DownloadStatus.completed,
      downloadedBytes: downloaded,
      totalBytes: total ?? current.totalBytes,
      speedBytesPerSecond: 0,
      updatedAt: DateTime.now(),
      clearError: true,
    ));
  }

  Future<void> _markFailure(String id, String? message,
      {bool paused = false}) async {
    final current = await _repository.getById(id);
    if (current == null) return;
    await _repository.upsert(current.copyWith(
      status: paused ? DownloadStatus.paused : DownloadStatus.failed,
      speedBytesPerSecond: 0,
      updatedAt: DateTime.now(),
      errorMessage: message,
    ));
  }

  Future<int> _fileLength(String path) async {
    final file = File(path);
    return await file.exists() ? file.length() : 0;
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

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
