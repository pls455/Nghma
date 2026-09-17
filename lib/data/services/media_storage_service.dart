import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../domain/entities/media_item.dart';

class MediaStorageService {
  const MediaStorageService();

  Future<String> createDestinationPath(MediaItem media) async {
    final root = await getExternalStorageDirectory() ??
        await getApplicationDocumentsDirectory();
    final directory = Directory(p.join(root.path, 'Naghama', 'Downloads'));
    await directory.create(recursive: true);

    final extension = _extensionFor(media);
    final baseName = _sanitizeFileName(media.title);
    final name = baseName.toLowerCase().endsWith('.$extension')
        ? baseName
        : '$baseName.$extension';

    var candidate = p.join(directory.path, name);
    var index = 1;
    while (await File(candidate).exists() || await File('$candidate.part').exists()) {
      candidate = p.join(directory.path, '$baseName ($index).$extension');
      index++;
    }
    return candidate;
  }

  String _extensionFor(MediaItem media) {
    final mime = media.mimeType?.toLowerCase();
    const mimeExtensions = <String, String>{
      'audio/mpeg': 'mp3',
      'audio/mp3': 'mp3',
      'audio/mp4': 'm4a',
      'audio/x-m4a': 'm4a',
      'audio/aac': 'aac',
      'audio/wav': 'wav',
      'audio/x-wav': 'wav',
      'audio/ogg': 'ogg',
      'audio/opus': 'opus',
      'audio/webm': 'webm',
      'audio/flac': 'flac',
      'video/mp4': 'mp4',
      'video/webm': 'webm',
      'video/x-matroska': 'mkv',
      'video/quicktime': 'mov',
    };
    if (mime != null && mimeExtensions.containsKey(mime)) {
      return mimeExtensions[mime]!;
    }

    final uri = Uri.tryParse(media.sourceUrl);
    final path = uri?.path ?? '';
    final extension = p.extension(path).replaceFirst('.', '').toLowerCase();
    return extension.isNotEmpty && extension.length <= 5 ? extension : 'mp3';
  }

  String _sanitizeFileName(String value) {
    final cleaned = value
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final withoutTrailingDots = cleaned.replaceFirst(RegExp(r'[. ]+$'), '');
    if (withoutTrailingDots.isEmpty) return 'media';
    return withoutTrailingDots.length > 120
        ? withoutTrailingDots.substring(0, 120).trim()
        : withoutTrailingDots;
  }
}
