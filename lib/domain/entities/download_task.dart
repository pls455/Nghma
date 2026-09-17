import 'media_item.dart';

enum DownloadStatus {
  queued,
  downloading,
  paused,
  completed,
  failed,
  cancelled,
}

class DownloadTask {
  const DownloadTask({
    required this.id,
    required this.media,
    required this.destinationPath,
    required this.status,
    required this.downloadedBytes,
    required this.totalBytes,
    required this.createdAt,
    required this.updatedAt,
    this.secondarySourceUrl,
    this.secondarySizeBytes,
    this.speedBytesPerSecond = 0,
    this.errorMessage,
  });

  final String id;
  final MediaItem media;
  final String destinationPath;
  final DownloadStatus status;
  final int downloadedBytes;
  final int? totalBytes;
  final String? secondarySourceUrl;
  final int? secondarySizeBytes;
  final int speedBytesPerSecond;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? errorMessage;

  bool get requiresMuxing => secondarySourceUrl != null;

  double get progress {
    final total = totalBytes;
    if (total == null || total <= 0) return 0;
    return (downloadedBytes / total).clamp(0, 1);
  }

  Duration? get estimatedRemaining {
    final total = totalBytes;
    if (total == null || speedBytesPerSecond <= 0) return null;
    final remaining = total - downloadedBytes;
    if (remaining <= 0) return Duration.zero;
    return Duration(seconds: (remaining / speedBytesPerSecond).ceil());
  }

  DownloadTask copyWith({
    DownloadStatus? status,
    int? downloadedBytes,
    int? totalBytes,
    String? secondarySourceUrl,
    int? secondarySizeBytes,
    int? speedBytesPerSecond,
    DateTime? updatedAt,
    String? errorMessage,
    bool clearError = false,
  }) {
    return DownloadTask(
      id: id,
      media: media,
      destinationPath: destinationPath,
      status: status ?? this.status,
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      totalBytes: totalBytes ?? this.totalBytes,
      secondarySourceUrl: secondarySourceUrl ?? this.secondarySourceUrl,
      secondarySizeBytes: secondarySizeBytes ?? this.secondarySizeBytes,
      speedBytesPerSecond:
          speedBytesPerSecond ?? this.speedBytesPerSecond,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}
