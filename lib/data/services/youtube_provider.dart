import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import '../../domain/entities/media_format.dart';
import '../../domain/entities/media_item.dart';
import '../../domain/repositories/content_provider.dart';

class YoutubeProvider implements ContentProvider {
  const YoutubeProvider();

  @override
  bool supports(Uri uri) {
    final host = uri.host.toLowerCase();
    return host == 'youtube.com' ||
        host.endsWith('.youtube.com') ||
        host == 'youtu.be' ||
        host == 'www.youtube-nocookie.com';
  }

  @override
  Future<bool> validateUrl(Uri uri) async {
    if (!supports(uri)) return false;
    return uri.host == 'youtu.be' ||
        uri.queryParameters['v']?.isNotEmpty == true ||
        uri.pathSegments.contains('shorts');
  }

  @override
  Future<MediaItem> fetchMetadata(Uri uri) async {
    final yt = YoutubeExplode();
    try {
      final video = await yt.videos.get(uri.toString());
      final manifest = await yt.videos.streams.getManifest(video.url);
      final formats = <MediaFormat>[];

      // Muxed streams include both video and audio, but are usually limited
      // to lower resolutions.
      for (final stream in manifest.muxed) {
        formats.add(_videoFormat(stream, idPrefix: 'yt-muxed'));
      }

      // Video-only streams contain the higher resolutions. The download
      // screen pairs the selected video stream with an audio-only stream and
      // DownloadManager muxes them into one playable file.
      for (final stream in manifest.videoOnly) {
        formats.add(_videoFormat(stream, idPrefix: 'yt-video'));
      }

      for (final stream in manifest.audioOnly) {
        formats.add(
          MediaFormat(
            id: 'yt-audio-${stream.tag}',
            url: stream.url.toString(),
            type: MediaFormatType.audio,
            label: stream.qualityLabel.isEmpty
                ? '${stream.bitrate.kiloBitsPerSecond.round()} kbps'
                : stream.qualityLabel,
            mimeType: _mimeForContainer(stream.container.name, audio: true),
            sizeBytes: stream.size.totalBytes,
            bitrate: stream.bitrate.bitsPerSecond,
          ),
        );
      }

      if (formats.isEmpty) {
        throw StateError('لم يُرجع المصدر أي صيغة قابلة للتنزيل.');
      }

      return MediaItem(
        id: video.id.value,
        title: video.title,
        sourceUrl: uri.toString(),
        duration: video.duration,
        thumbnailUrl: null,
        formats: formats,
      );
    } finally {
      yt.close();
    }
  }

  MediaFormat _videoFormat(dynamic stream, {required String idPrefix}) {
    return MediaFormat(
      id: '$idPrefix-${stream.tag}',
      url: stream.url.toString(),
      type: MediaFormatType.video,
      label: stream.qualityLabel,
      mimeType: _mimeForContainer(stream.container.name),
      sizeBytes: stream.size.totalBytes,
      bitrate: stream.bitrate.bitsPerSecond,
      width: stream.videoResolution.width,
      height: stream.videoResolution.height,
    );
  }

  String _mimeForContainer(String container, {bool audio = false}) {
    switch (container.toLowerCase()) {
      case 'mp4':
        return audio ? 'audio/mp4' : 'video/mp4';
      case 'webm':
        return audio ? 'audio/webm' : 'video/webm';
      case 'm3u8':
        return 'application/vnd.apple.mpegurl';
      case '3gpp':
        return 'video/3gpp';
      default:
        return 'application/octet-stream';
    }
  }
}
