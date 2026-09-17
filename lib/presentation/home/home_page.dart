import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/sqlite_download_repository.dart';
import '../../data/services/download_manager.dart';
import '../../data/services/media_storage_service.dart';
import '../../domain/entities/media_format.dart';
import '../../domain/entities/media_item.dart';
import '../downloads/downloads_controller.dart';
import 'home_controller.dart';

final mediaStorageServiceProvider = Provider<MediaStorageService>((ref) => const MediaStorageService());
final homeDownloadManagerProvider = Provider<DownloadManager>((ref) => DownloadManager(repository: SqliteDownloadRepository()));

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});
  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final _controller = TextEditingController();

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  Future<void> _analyze() async {
    final value = _controller.text.trim();
    if (value.isEmpty) { _showMessage('أدخل رابط المحتوى أولاً.'); return; }
    ref.read(homeAnalysisProvider.notifier).state = const AsyncLoading();
    try {
      final media = await ref.read(analyzeMediaUrlProvider)(value);
      if (!mounted) return;
      ref.read(homeAnalysisProvider.notifier).state = AsyncData(media);
      await _showMediaDetails(media);
    } catch (error) {
      if (!mounted) return;
      ref.read(homeAnalysisProvider.notifier).state = AsyncError(error, StackTrace.current);
      _showMessage(_friendlyError(error));
    }
  }

  Future<void> _startDownload(MediaItem media, MediaFormat format, {MediaFormat? audioFormat}) async {
    final storage = ref.read(mediaStorageServiceProvider);
    final manager = ref.read(homeDownloadManagerProvider);
    final selectedMedia = MediaItem(
      id: '${media.id}:${format.id}',
      title: media.title,
      sourceUrl: format.url,
      mimeType: format.mimeType ?? media.mimeType,
      duration: media.duration,
      sizeBytes: format.sizeBytes ?? media.sizeBytes,
      thumbnailUrl: media.thumbnailUrl,
      formats: [format],
    );
    try {
      final destinationPath = await storage.createDestinationPath(selectedMedia);
      await manager.enqueue(
        media: selectedMedia,
        destinationPath: destinationPath,
        secondarySourceUrl: audioFormat?.url,
        secondarySizeBytes: audioFormat?.sizeBytes,
      );
      if (!mounted) return;
      ref.invalidate(downloadsControllerProvider);
      Navigator.pop(context);
      _showMessage(audioFormat == null ? 'أضيف المحتوى إلى قائمة التنزيلات.' : 'أضيف الفيديو، وسيتم دمج الصوت بعد اكتمال التنزيل.');
    } catch (_) {
      if (!mounted) return;
      _showMessage('تعذر تجهيز ملف التنزيل. تحقق من مساحة التخزين.');
    }
  }

  Future<void> _showMediaDetails(MediaItem media) async {
    var type = media.videoFormats.isNotEmpty ? MediaFormatType.video : MediaFormatType.audio;
    MediaFormat? selectedVideo = media.videoFormats.isEmpty ? null : media.videoFormats.first;
    MediaFormat? selectedAudio = media.audioFormats.isEmpty ? null : media.audioFormats.first;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final formats = type == MediaFormatType.video ? media.videoFormats : media.audioFormats;
          final selected = type == MediaFormatType.video ? selectedVideo : selectedAudio;
          final canMux = type == MediaFormatType.video && selectedVideo != null && media.audioFormats.isNotEmpty;
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('تم تحليل المحتوى', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 14),
                  Card(child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.movie)),
                    title: Text(media.title),
                    subtitle: Text(media.sourceUrl, maxLines: 2, overflow: TextOverflow.ellipsis),
                  )),
                  const SizedBox(height: 14),
                  Text('نوع التنزيل', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: ChoiceChip(
                      label: const SizedBox(width: double.infinity, child: Center(child: Text('🎬 فيديو'))),
                      selected: type == MediaFormatType.video,
                      onSelected: media.videoFormats.isEmpty ? null : (_) => setModalState(() { type = MediaFormatType.video; }),
                    )),
                    const SizedBox(width: 10),
                    Expanded(child: ChoiceChip(
                      label: const SizedBox(width: double.infinity, child: Center(child: Text('🎵 صوت'))),
                      selected: type == MediaFormatType.audio,
                      onSelected: media.audioFormats.isEmpty ? null : (_) => setModalState(() { type = MediaFormatType.audio; }),
                    )),
                  ]),
                  const SizedBox(height: 14),
                  Text('الجودة', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  if (formats.isEmpty)
                    const Text('لا توجد صيغة متاحة لهذا النوع.')
                  else
                    DropdownButtonFormField<MediaFormat>(
                      value: selected,
                      isExpanded: true,
                      decoration: const InputDecoration(border: OutlineInputBorder(), prefixIcon: Icon(Icons.high_quality_outlined)),
                      items: formats.map((format) => DropdownMenuItem<MediaFormat>(value: format, child: Text(_formatLabel(format)))).toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setModalState(() {
                          if (type == MediaFormatType.video) { selectedVideo = value; } else { selectedAudio = value; }
                        });
                      },
                    ),
                  if (canMux) ...[
                    const SizedBox(height: 10),
                    Text('سيتم تنزيل مسار الفيديو والصوت ثم دمجهما في ملف واحد.', style: Theme.of(context).textTheme.bodySmall),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: selected == null ? null : () => _startDownload(media, selected, audioFormat: canMux ? selectedAudio : null),
                      icon: const Icon(Icons.download_outlined),
                      label: Text(type == MediaFormatType.video ? 'تنزيل الفيديو' : 'تنزيل النغمة'),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('الجودات المعروضة هي التي أعادها المصدر فعليًا، بدون اختراع 720p من العدم.', style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatLabel(MediaFormat format) {
    final parts = <String>[];
    if (format.label?.isNotEmpty == true) parts.add(format.label!);
    if (format.width != null && format.height != null) parts.add('${format.width}×${format.height}');
    if (format.bitrate != null && format.bitrate! > 0) parts.add('${(format.bitrate! / 1000).round()} kbps');
    return parts.isEmpty ? 'جودة المصدر' : parts.join(' • ');
  }

  String _friendlyError(Object error) {
    if (error is UnsupportedError) return 'هذا المصدر غير مدعوم حاليًا.';
    if (error is FormatException) return error.message.toString();
    if (error is StateError) return error.message;
    return 'تعذر تحليل الرابط. تحقق منه وحاول مرة أخرى.';
  }

  void _showMessage(String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final analysis = ref.watch(homeAnalysisProvider);
    return SafeArea(
      child: CustomScrollView(slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
          sliver: SliverToBoxAdapter(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('نغمة', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text('الصق الرابط، اختر النوع والجودة، ثم نزّل الملف.', style: theme.textTheme.bodyMedium),
            const SizedBox(height: 28),
            Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('رابط الفيديو', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              TextField(controller: _controller, keyboardType: TextInputType.url, textDirection: TextDirection.ltr, decoration: const InputDecoration(hintText: 'https://youtube.com/watch?v=...', prefixIcon: Icon(Icons.link)), onSubmitted: (_) => _analyze()),
              const SizedBox(height: 12),
              SizedBox(width: double.infinity, child: FilledButton.icon(
                onPressed: analysis.isLoading ? null : _analyze,
                icon: analysis.isLoading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.manage_search),
                label: Text(analysis.isLoading ? 'جارٍ التحليل...' : 'تحليل الرابط'),
              )),
            ]))),
            const SizedBox(height: 24),
            Text('النشاط الأخير', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            const _EmptySection(icon: Icons.history, title: 'لا يوجد نشاط بعد', subtitle: 'التنزيلات المكتملة ستظهر هنا.'),
          ])),
        ),
      ]),
    );
  }
}

class _EmptySection extends StatelessWidget {
  const _EmptySection({required this.icon, required this.title, required this.subtitle});
  final IconData icon;
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(child: Padding(padding: const EdgeInsets.all(22), child: Row(children: [
      Icon(icon, size: 30, color: theme.colorScheme.primary),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(subtitle, style: theme.textTheme.bodySmall),
      ])),
    ])));
  }
}
