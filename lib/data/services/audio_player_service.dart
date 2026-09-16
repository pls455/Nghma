import 'dart:async';
import 'dart:io';

import 'package:just_audio/just_audio.dart';

import '../../domain/entities/download_task.dart';

class AudioPlayerService {
  AudioPlayerService() : _player = AudioPlayer();

  final AudioPlayer _player;
  List<DownloadTask> _queue = const [];

  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<int?> get currentIndexStream => _player.currentIndexStream;
  Stream<LoopMode> get loopModeStream => _player.loopModeStream;
  Stream<bool> get shuffleModeEnabledStream => _player.shuffleModeEnabledStream;

  DownloadTask? get currentTask {
    final index = _player.currentIndex;
    if (index == null || index < 0 || index >= _queue.length) return null;
    return _queue[index];
  }

  Future<void> playTask(
    DownloadTask task, {
    List<DownloadTask>? queue,
  }) async {
    final requestedQueue = queue ?? [task];
    final validQueue = <DownloadTask>[];
    for (final item in requestedQueue) {
      if (await File(item.destinationPath).exists()) {
        validQueue.add(item);
      }
    }

    if (validQueue.isEmpty) {
      throw const AudioPlayerException('الملف الصوتي غير موجود على الجهاز.');
    }

    var index = validQueue.indexWhere((item) => item.id == task.id);
    if (index < 0) {
      validQueue.insert(0, task);
      index = 0;
    }

    _queue = List.unmodifiable(validQueue);
    final sources = _queue
        .map((item) => AudioSource.file(item.destinationPath, tag: item.id))
        .toList(growable: false);

    await _player.setAudioSources(sources, initialIndex: index);
    await _player.play();
  }

  Future<void> togglePlayPause() async {
    if (_player.playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  Future<void> seek(Duration position) => _player.seek(position);

  Future<void> next() async {
    if (_player.hasNext) {
      await _player.seekToNext();
    }
  }

  Future<void> previous() async {
    if (_player.hasPrevious) {
      await _player.seekToPrevious();
    } else {
      await _player.seek(Duration.zero);
    }
  }

  Future<void> stop() => _player.stop();

  Future<void> toggleRepeat() async {
    final nextMode = switch (_player.loopMode) {
      LoopMode.off => LoopMode.all,
      LoopMode.all => LoopMode.one,
      LoopMode.one => LoopMode.off,
    };
    await _player.setLoopMode(nextMode);
  }

  Future<void> toggleShuffle() =>
      _player.setShuffleModeEnabled(!_player.shuffleModeEnabled);

  Future<void> dispose() => _player.dispose();
}

class AudioPlayerException implements Exception {
  const AudioPlayerException(this.message);

  final String message;

  @override
  String toString() => message;
}
