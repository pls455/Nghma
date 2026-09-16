class MediaItem {
  const MediaItem({
    required this.id,
    required this.title,
    required this.sourceUrl,
    this.mimeType,
    this.duration,
    this.sizeBytes,
    this.thumbnailUrl,
  });

  final String id;
  final String title;
  final String sourceUrl;
  final String? mimeType;
  final Duration? duration;
  final int? sizeBytes;
  final String? thumbnailUrl;
}
