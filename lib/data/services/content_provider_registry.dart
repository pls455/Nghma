import '../../domain/repositories/content_provider.dart';
import 'direct_url_provider.dart';
import 'youtube_provider.dart';

class ContentProviderRegistry {
  ContentProviderRegistry({List<ContentProvider>? providers})
      : providers = providers ?? const [
          YoutubeProvider(),
          DirectUrlProvider(),
        ];

  final List<ContentProvider> providers;
}
