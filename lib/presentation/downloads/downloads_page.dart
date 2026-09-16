import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/download_task.dart';
import 'downloads_controller.dart';

class DownloadsPage extends ConsumerWidget {
  const DownloadsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(downloadsControllerProvider);

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () => ref.read(downloadsControllerProvider.notifier).refresh(),
        child: state.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(height: MediaQuery.sizeOf(context).height * .3),
              _EmptyState(
                icon: Icons.error_outline,
                title: 'تعذر تحميل التنزيلات',
                description: error.toString(),
              ),
            ],
          ),
          data: (tasks) => tasks.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(height: MediaQuery.sizeOf(context).height * .3),
                    const _EmptyState(
                      icon: Icons.download_outlined,
                      title: 'لا توجد تنزيلات',
                      description: 'عند بدء تنزيل حقيقي ستظهر حالته هنا مع التقدم والسرعة والتحكم.',
                    ),
                  ],
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 110),
                  itemCount: tasks.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) => _DownloadCard(task: tasks[index]),
                ),
        ),
      ),
    );
  }
}

class _DownloadCard extends ConsumerWidget {
  const _DownloadCard({required this.task});

  final DownloadTask task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final controller = ref.read(downloadsControllerProvider.notifier);
    final progress = task.progress;
    final isActive = task.status == DownloadStatus.downloading;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Icon(Icons.music_note, color: theme.colorScheme.onPrimaryContainer),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    task.media.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'pause') await controller.pause(task.id);
                    if (value == 'resume') await controller.resume(task.id);
                    if (value == 'cancel') await controller.cancel(task.id);
                  },
                  itemBuilder: (_) => [
                    if (isActive) const PopupMenuItem(value: 'pause', child: Text('إيقاف مؤقت')),
                    if (task.status == DownloadStatus.paused || task.status == DownloadStatus.failed)
                      const PopupMenuItem(value: 'resume', child: Text('استئناف')),
                    if (task.status != DownloadStatus.completed && task.status != DownloadStatus.cancelled)
                      const PopupMenuItem(value: 'cancel', child: Text('إلغاء')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            LinearProgressIndicator(value: task.totalBytes == null ? null : progress),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(_statusLabel(task.status), style: theme.textTheme.bodySmall),
                const Spacer(),
                if (task.speedBytesPerSecond > 0)
                  Text('${_formatBytes(task.speedBytesPerSecond)}/ث', style: theme.textTheme.bodySmall),
                if (task.totalBytes != null) ...[
                  const SizedBox(width: 10),
                  Text('${(progress * 100).round()}%', style: theme.textTheme.bodySmall),
                ],
              ],
            ),
            if (task.errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(task.errorMessage!, style: TextStyle(color: theme.colorScheme.error)),
            ],
          ],
        ),
      ),
    );
  }

  String _statusLabel(DownloadStatus status) {
    switch (status) {
      case DownloadStatus.queued:
        return 'في الانتظار';
      case DownloadStatus.downloading:
        return 'جارٍ التنزيل';
      case DownloadStatus.paused:
        return 'متوقف مؤقتًا';
      case DownloadStatus.completed:
        return 'اكتمل';
      case DownloadStatus.failed:
        return 'فشل';
      case DownloadStatus.cancelled:
        return 'ملغى';
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.title, required this.description});

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            Icon(icon, size: 52, color: theme.colorScheme.primary),
            const SizedBox(height: 18),
            Text(title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(description, style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
