import '../../domain/entities/media_format.dart';
import '../../domain/entities/media_item.dart';
import '../../domain/repositories/content_provider.dart';

class DirectUrlProvider implements ContentProvider {
  const DirectUrlProvider();

  static const _videoExtensions = <String>{
    'mp4',
    'webm',
    'mkv',
    'mov',
  };

  static const _audioExtensions = <String>{
    'mp3',
    'm4a',
    'aac',
    'wav',
    'ogg',
    'opus',
    'flac',
  };

  @override
  bool supports(Uri uri) {
    final extension = _extension(uri);
    return _videoExtensions.contains(extension) ||
        _audioExtensions.contains(extension);
  }

  @override
  Future<bool> validateUrl(Uri uri) async {
    return (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty &&
        supports(uri);
  }

  @override
  Future<MediaItem> fetchMetadata(Uri uri) async {
    if (!await validateUrl(uri)) {
      throw const FormatException('Unsupported media URL');
    }

    final filename = uri.pathSegments.isEmpty ? 'media' : uri.pathSegments.last;
    final extension = _extension(uri);
    final isVideo = _videoExtensions.contains(extension);
    final type = isVideo ? MediaFormatType.video : MediaFormatType.audio;
    final mimeType = isVideo ? 'video/$extension' : 'audio/$extension';

    return MediaItem(
      id: uri.toString(),
      title: filename,
      sourceUrl: uri.toString(),
      mimeType: mimeType,
      formats: [
        MediaFormat(
          id: uri.toString(),
          url: uri.toString(),
          type: type,
          mimeType: mimeType,
          label: 'جودة المصدر',
        ),
      ],
    );
  }

  String _extension(Uri uri) {
    final path = uri.path.toLowerCase();
    final lastDot = path.lastIndexOf('.');
    if (lastDot == -1 || lastDot == path.length - 1) return '';
    return path.substring(lastDot + 1);
  }
}
