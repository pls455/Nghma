import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'data/services/download_background_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DownloadBackgroundService.initialize();
  runApp(const ProviderScope(child: NaghmaApp()));
}
