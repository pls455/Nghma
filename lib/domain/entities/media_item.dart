import 'media_format.dart';

class MediaItem {
  const MediaItem({
    required this.id,
    required this.title,
    required this.sourceUrl,
    this.mimeType,
    this.duration,
    this.sizeBytes,
    this.thumbnailUrl,
    this.formats = const [],
  });

  final String id;
  final String title;
  final String sourceUrl;
  final String? mimeType;
  final Duration? duration;
  final int? sizeBytes;
  final String? thumbnailUrl;
  final List<MediaFormat> formats;

  List<MediaFormat> get videoFormats =>
      formats.where((format) => format.type == MediaFormatType.video).toList();

  List<MediaFormat> get audioFormats =>
      formats.where((format) => format.type == MediaFormatType.audio).toList();
}
