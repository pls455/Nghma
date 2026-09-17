import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';

class MediaMuxer {
  const MediaMuxer();

  Future<void> mux({
    required String videoPath,
    required String audioPath,
    required String outputPath,
  }) async {
    final video = _quote(videoPath);
    final audio = _quote(audioPath);
    final output = _quote(outputPath);
    final command = '-y -i $video -i $audio -map 0:v:0 -map 1:a:0 '
        '-c:v copy -c:a aac -b:a 192k -shortest $output';

    final session = await FFmpegKit.execute(command);
    final code = await session.getReturnCode();
    if (!ReturnCode.isSuccess(code)) {
      throw const MediaMuxerException('تعذر دمج مسار الفيديو والصوت.');
    }
  }

  String _quote(String value) {
    return "'${value.replaceAll("'", "'\\''")}'";
  }
}

class MediaMuxerException implements Exception {
  const MediaMuxerException(this.message);

  final String message;

  @override
  String toString() => message;
}
