import 'dart:async';
import 'dart:io';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import '../../domain/entities/download_task.dart';
import '../../data/repositories/sqlite_download_repository.dart';
import 'download_manager.dart';

class DownloadBackgroundService {
  static Future<void> initialize() async {
    FlutterForegroundTask.initCommunicationPort();
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'naghma_downloads',
        channelName: 'تنزيلات نغمة',
        channelDescription: 'يعرض تقدم تنزيلات نغمة في الخلفية.',
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(showNotification: false, playSound: false),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(1000),
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  static Future<void> start() async {
    if (!Platform.isAndroid) return;
    final permission = await FlutterForegroundTask.checkNotificationPermission();
    if (permission != NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
    }
    if (await FlutterForegroundTask.isRunningService) return;
    await FlutterForegroundTask.startService(
      serviceId: 19017,
      notificationTitle: 'نغمة',
      notificationText: 'جاري تجهيز التنزيلات...',
      callback: startCallback,
    );
  }

  static Future<void> stop() async {
    if (await FlutterForegroundTask.isRunningService) await FlutterForegroundTask.stopService();
  }
}

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(DownloadTaskHandler());
}

class DownloadTaskHandler extends TaskHandler {
  final DownloadManager _manager = DownloadManager(repository: SqliteDownloadRepository());

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async => _tick();

  @override
  void onRepeatEvent(DateTime timestamp) => unawaited(_tick());

  Future<void> _tick() async {
    await _manager.pump();
    final tasks = await _manager.getTasks();
    final active = tasks.where((task) => task.status == DownloadStatus.downloading || task.status == DownloadStatus.queued).toList();
    if (active.isEmpty) {
      await DownloadBackgroundService.stop();
      return;
    }

    final task = active.first;
    final downloaded = task.downloadedBytes;
    final total = task.totalBytes;
    final text = total != null && total > 0
        ? '${(downloaded * 100 / total).clamp(0, 100).round()}% • ${_mb(downloaded)} / ${_mb(total)}'
        : '${_mb(downloaded)} تم تنزيله';
    await FlutterForegroundTask.updateService(notificationTitle: 'نغمة • تنزيل', notificationText: text);
  }

  String _mb(int bytes) => '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}
}
