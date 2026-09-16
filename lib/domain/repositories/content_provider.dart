import '../entities/media_item.dart';

abstract interface class ContentProvider {
  bool supports(Uri uri);

  Future<bool> validateUrl(Uri uri);

  Future<MediaItem> fetchMetadata(Uri uri);
}
