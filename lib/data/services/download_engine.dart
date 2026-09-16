import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';

class DownloadEngine {
  DownloadEngine({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  Future<DownloadResult> download({
    required String url,
    required String partPath,
    required CancelToken cancelToken,
    required void Function(int downloadedBytes, int? totalBytes, int speed)
        onProgress,
  }) async {
    final partFile = File(partPath);
    final existingBytes = await partFile.exists() ? await partFile.length() : 0;
    final startedAt = DateTime.now();
    var lastSampleTime = startedAt;
    var lastSampleBytes = existingBytes;

    final response = await _dio.get<ResponseBody>(
      url,
      cancelToken: cancelToken,
      options: Options(
        responseType: ResponseType.stream,
        followRedirects: true,
        validateStatus: (status) => status != null && status >= 200 && status < 400,
        headers: existingBytes > 0 ? {'Range': 'bytes=$existingBytes-'} : null,
      ),
    );

    final body = response.data;
    if (body == null) {
      throw const DownloadEngineException('لم يصل محتوى الملف من المصدر.');
    }

    final resumed = existingBytes > 0 && response.statusCode == 206;
    final initialBytes = resumed ? existingBytes : 0;

    // Some servers ignore Range and return 200. In that case the partial file
    // must be replaced rather than corrupted by appending a second copy.
    if (!resumed && existingBytes > 0) {
      await partFile.writeAsBytes(const <int>[], flush: true);
    }

    final responseLength = body.contentLength;
    final totalBytes = responseLength >= 0
        ? initialBytes + responseLength
        : _totalFromContentRange(response.headers, initialBytes, responseLength);
    var downloaded = initialBytes;

    final sink = partFile.openWrite(
      mode: resumed ? FileMode.append : FileMode.write,
    );

    try {
      await for (final chunk in body.stream) {
        cancelToken.throwIfRequested();
        sink.add(chunk);
        downloaded += chunk.length;

        final now = DateTime.now();
        final elapsedMs = now.difference(lastSampleTime).inMilliseconds;
        if (elapsedMs >= 500) {
          final deltaBytes = downloaded - lastSampleBytes;
          final speed = deltaBytes * 1000 ~/ elapsedMs;
          onProgress(downloaded, totalBytes, speed);
          lastSampleTime = now;
          lastSampleBytes = downloaded;
        }
      }
      await sink.flush();
    } finally {
      await sink.close();
    }

    final averageSpeed = _averageSpeed(
      downloaded - initialBytes,
      DateTime.now().difference(startedAt),
    );
    onProgress(downloaded, totalBytes, averageSpeed);

    return DownloadResult(
      downloadedBytes: downloaded,
      totalBytes: totalBytes,
    );
  }

  int? _totalFromContentRange(
    Headers headers,
    int initialBytes,
    int responseLength,
  ) {
    final values = headers['content-range'];
    if (values == null || values.isEmpty) return null;
    final match = RegExp(r'/([0-9]+)$').firstMatch(values.first);
    if (match == null) return null;
    return int.tryParse(match.group(1)!);
  }

  int _averageSpeed(int bytes, Duration elapsed) {
    if (bytes <= 0 || elapsed.inMilliseconds <= 0) return 0;
    return bytes * 1000 ~/ elapsed.inMilliseconds;
  }
}

class DownloadResult {
  const DownloadResult({required this.downloadedBytes, this.totalBytes});

  final int downloadedBytes;
  final int? totalBytes;
}

class DownloadEngineException implements Exception {
  const DownloadEngineException(this.message);

  final String message;

  @override
  String toString() => message;
}
