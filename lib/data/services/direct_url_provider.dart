import '../../domain/entities/media_item.dart';
import '../../domain/repositories/content_provider.dart';

class DirectUrlProvider implements ContentProvider {
  const DirectUrlProvider();

  static const _mediaExtensions = <String>{
    'mp3',
    'm4a',
    'aac',
    'wav',
    'ogg',
    'opus',
    'flac',
    'mp4',
    'webm',
    'mkv',
    'mov',
  };

  @override
  bool supports(Uri uri) {
    final path = uri.path.toLowerCase();
    final extension = path.contains('.') ? path.split('.').last : '';
    return _mediaExtensions.contains(extension);
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

    final filename = uri.pathSegments.isEmpty
        ? 'media'
        : uri.pathSegments.last;

    return MediaItem(
      id: uri.toString(),
      title: filename,
      sourceUrl: uri.toString(),
    );
  }
}
