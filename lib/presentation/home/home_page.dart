import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/sqlite_download_repository.dart';
import '../../data/services/download_manager.dart';
import '../../data/services/media_storage_service.dart';
import '../../domain/entities/media_item.dart';
import '../downloads/downloads_controller.dart';
import 'home_controller.dart';

final mediaStorageServiceProvider = Provider<MediaStorageService>(
  (ref) => const MediaStorageService(),
);

final homeDownloadManagerProvider = Provider<DownloadManager>(
  (ref) => DownloadManager(repository: SqliteDownloadRepository()),
);

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _analyze() async {
    final value = _controller.text.trim();
    if (value.isEmpty) {
      _showMessage('أدخل رابط المحتوى أولاً.');
      return;
    }

    ref.read(homeAnalysisProvider.notifier).state = const AsyncLoading();
    try {
      final media = await ref.read(analyzeMediaUrlProvider)(value);
      if (!mounted) return;
      ref.read(homeAnalysisProvider.notifier).state = AsyncData(media);
      await _showMediaDetails(media);
    } catch (error) {
      if (!mounted) return;
      ref.read(homeAnalysisProvider.notifier).state =
          AsyncError(error, StackTrace.current);
      _showMessage(_friendlyError(error));
    }
  }

  Future<void> _startDownload(MediaItem media) async {
    final storage = ref.read(mediaStorageServiceProvider);
    final manager = ref.read(homeDownloadManagerProvider);

    try {
      final destinationPath = await storage.createDestinationPath(media);
      await manager.enqueue(
        media: media,
        destinationPath: destinationPath,
      );

      if (!mounted) return;
      ref.invalidate(downloadsControllerProvider);
      Navigator.pop(context);
      _showMessage('أضيف المحتوى إلى قائمة التنزيلات.');
    } catch (_) {
      if (!mounted) return;
      _showMessage('تعذر تجهيز ملف التنزيل. تحقق من مساحة التخزين.');
    }
  }

  Future<void> _showMediaDetails(MediaItem media) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        final theme = Theme.of(context);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'تم تحليل المحتوى',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 18),
                Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Icon(
                        Icons.music_note,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    title: Text(media.title),
                    subtitle: Text(
                      media.sourceUrl,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => _startDownload(media),
                    icon: const Icon(Icons.download_outlined),
                    label: const Text('بدء التنزيل'),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'سيُحفظ الملف داخل مساحة التطبيق المخصصة للتنزيلات.',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _friendlyError(Object error) {
    if (error is UnsupportedError) return 'هذا المصدر غير مدعوم حاليًا.';
    if (error is FormatException) return error.message.toString();
    if (error is StateError) return error.message;
    return 'تعذر تحليل الرابط. تحقق منه وحاول مرة أخرى.';
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final analysis = ref.watch(homeAnalysisProvider);

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'نغمة',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'نزّل ما تملك حق تنزيله، ثم احتفظ به في مكتبتك.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 28),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'إضافة رابط',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'الصق رابط المحتوى المسموح بتنزيله.',
                            style: theme.textTheme.bodySmall,
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _controller,
                            keyboardType: TextInputType.url,
                            textDirection: TextDirection.ltr,
                            decoration: const InputDecoration(
                              hintText: 'https://example.com/media.mp3',
                              prefixIcon: Icon(Icons.link),
                            ),
                            onSubmitted: (_) => _analyze(),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: analysis.isLoading ? null : _analyze,
                              icon: analysis.isLoading
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.manage_search),
                              label: Text(
                                analysis.isLoading
                                    ? 'جارٍ التحليل...'
                                    : 'تحليل الرابط',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'النشاط الأخير',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const _EmptySection(
                    icon: Icons.history,
                    title: 'لا يوجد نشاط بعد',
                    subtitle: 'التنزيلات المكتملة ستظهر هنا.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptySection extends StatelessWidget {
  const _EmptySection({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Row(
          children: [
            Icon(icon, size: 30, color: theme.colorScheme.primary),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
