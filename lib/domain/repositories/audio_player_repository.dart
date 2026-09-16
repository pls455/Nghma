import '../entities/media_item.dart';

abstract interface class AudioPlayerRepository {
  Future<void> load(MediaItem media, String localPath);
  Future<void> play();
  Future<void> pause();
  Future<void> seek(Duration position);
  Future<void> stop();
  Future<void> dispose();
}
