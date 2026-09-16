import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../domain/entities/download_task.dart';
import 'player_controller.dart';

class PlayerPage extends ConsumerWidget {
  const PlayerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final service = ref.watch(audioPlayerServiceProvider);
    final playerState = ref.watch(playerStateProvider).valueOrNull;
    final task = service.currentTask;
    final position = ref.watch(playerPositionProvider).valueOrNull ?? Duration.zero;
    final duration = ref.watch(playerDurationProvider).valueOrNull ?? Duration.zero;
    final loopMode = ref.watch(playerLoopModeProvider).valueOrNull ?? LoopMode.off;
    final shuffle = ref.watch(playerShuffleProvider).valueOrNull ?? false;
    final isPlaying = playerState?.playing ?? false;

    if (task == null) {
      return const _EmptyPlayer();
    }

    final maxSeconds = duration.inMilliseconds > 0
        ? duration.inMilliseconds.toDouble()
        : 1.0;
    final value = position.inMilliseconds.clamp(0, maxSeconds.toInt()).toDouble();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        children: [
          Text(
            'المشغل',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 28),
          Container(
            width: double.infinity,
            height: 300,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Icon(
              Icons.music_note_rounded,
              size: 112,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            task.media.title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'ملف محلي',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 26),
          Slider(
            value: value,
            max: maxSeconds,
            onChanged: duration.inMilliseconds <= 0
                ? null
                : (newValue) => service.seek(
                      Duration(milliseconds: newValue.round()),
                    ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_formatDuration(position)),
                Text(_formatDuration(duration)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                tooltip: shuffle ? 'إيقاف الترتيب العشوائي' : 'ترتيب عشوائي',
                onPressed: service.toggleShuffle,
                icon: Icon(
                  Icons.shuffle_rounded,
                  color: shuffle ? theme.colorScheme.primary : null,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'السابق',
                onPressed: service.previous,
                icon: const Icon(Icons.skip_previous_rounded, size: 34),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: service.togglePlayPause,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(64, 64),
                  shape: const CircleBorder(),
                ),
                child: Icon(
                  isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  size: 32,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'التالي',
                onPressed: service.next,
                icon: const Icon(Icons.skip_next_rounded, size: 34),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'التكرار',
                onPressed: service.toggleRepeat,
                icon: Icon(
                  loopMode == LoopMode.one
                      ? Icons.repeat_one_rounded
                      : Icons.repeat_rounded,
                  color: loopMode != LoopMode.off
                      ? theme.colorScheme.primary
                      : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: service.stop,
            icon: const Icon(Icons.stop_circle_outlined),
            label: const Text('إيقاف المشغل'),
          ),
        ],
      ),
    );
  }

  static String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    final hours = duration.inHours;
    if (hours > 0) return '$hours:$minutes:$seconds';
    return '$minutes:$seconds';
  }
}

class _EmptyPlayer extends StatelessWidget {
  const _EmptyPlayer();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.graphic_eq_rounded, size: 70, color: theme.colorScheme.primary),
              const SizedBox(height: 18),
              Text(
                'لا يوجد ملف قيد التشغيل',
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              const Text(
                'نزّل ملفاً أولاً من المكتبة ثم شغّله من زر التشغيل.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
