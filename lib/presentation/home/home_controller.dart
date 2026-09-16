import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/content_provider_registry.dart';
import '../../data/services/default_policy_repository.dart';
import '../../domain/entities/media_item.dart';
import '../../domain/usecases/analyze_media_url.dart';

final analyzeMediaUrlProvider = Provider<AnalyzeMediaUrl>((ref) {
  return AnalyzeMediaUrl(
    providers: ContentProviderRegistry().providers,
    policy: const DefaultPolicyRepository(),
  );
});

final homeAnalysisProvider = StateProvider<AsyncValue<MediaItem?>>((ref) {
  return const AsyncData(null);
});
