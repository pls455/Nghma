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
        headers: existingBytes > 0 ? {'Range': 'bytes=$existingBytes-'} : null,
      ),
    );

    final resumed = existingBytes > 0 && response.statusCode == 206;
    final initialBytes = resumed ? existingBytes : 0;
    if (!resumed && existingBytes > 0) {
      await partFile.writeAsBytes(const <int>[], flush: true);
    }

    final responseLength = response.data?.contentLength ?? -1;
    final totalBytes = responseLength >= 0
        ? initialBytes + responseLength
        : null;
    var downloaded = initialBytes;

    final sink = partFile.openWrite(
      mode: resumed ? FileMode.append : FileMode.write,
    );

    try {
      await for (final chunk in response.data!.stream) {
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

    onProgress(downloaded, totalBytes, _averageSpeed(
      downloaded - initialBytes,
      DateTime.now().difference(startedAt),
    ));

    return DownloadResult(
      downloadedBytes: downloaded,
      totalBytes: totalBytes,
    );
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
