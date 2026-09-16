import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../data/services/audio_player_service.dart';
import '../../domain/entities/download_task.dart';

final audioPlayerServiceProvider = Provider<AudioPlayerService>((ref) {
  final service = AudioPlayerService();
  ref.onDispose(service.dispose);
  return service;
});

final playerStateProvider = StreamProvider<PlayerState>((ref) {
  return ref.watch(audioPlayerServiceProvider).playerStateStream;
});

final playerPositionProvider = StreamProvider<Duration>((ref) {
  return ref.watch(audioPlayerServiceProvider).positionStream;
});

final playerDurationProvider = StreamProvider<Duration?>((ref) {
  return ref.watch(audioPlayerServiceProvider).durationStream;
});

final playerCurrentIndexProvider = StreamProvider<int?>((ref) {
  return ref.watch(audioPlayerServiceProvider).currentIndexStream;
});

final playerLoopModeProvider = StreamProvider<LoopMode>((ref) {
  return ref.watch(audioPlayerServiceProvider).loopModeStream;
});

final playerShuffleProvider = StreamProvider<bool>((ref) {
  return ref.watch(audioPlayerServiceProvider).shuffleModeEnabledStream;
});

final currentPlayerTaskProvider = Provider<DownloadTask?>((ref) {
  final index = ref.watch(playerCurrentIndexProvider).valueOrNull;
  final service = ref.watch(audioPlayerServiceProvider);
  if (index == null) return service.currentTask;
  return service.currentTask;
});
