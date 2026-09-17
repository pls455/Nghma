enum MediaFormatType { video, audio }

class MediaFormat {
  const MediaFormat({
    required this.id,
    required this.url,
    required this.type,
    this.label,
    this.mimeType,
    this.sizeBytes,
    this.bitrate,
    this.width,
    this.height,
  });

  final String id;
  final String url;
  final MediaFormatType type;
  final String? label;
  final String? mimeType;
  final int? sizeBytes;
  final int? bitrate;
  final int? width;
  final int? height;
}
