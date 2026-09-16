import '../entities/media_item.dart';
import '../repositories/content_provider.dart';
import '../repositories/policy_repository.dart';

class AnalyzeMediaUrl {
  const AnalyzeMediaUrl({
    required this.providers,
    required this.policy,
  });

  final List<ContentProvider> providers;
  final PolicyRepository policy;

  Future<MediaItem> call(String rawUrl) async {
    final uri = Uri.tryParse(rawUrl.trim());
    if (uri == null || uri.host.isEmpty) {
      throw const FormatException('أدخل رابطاً صحيحاً.');
    }

    final provider = providers.where((item) => item.supports(uri)).firstOrNull;
    if (provider == null) {
      throw UnsupportedError('المصدر غير مدعوم حالياً.');
    }

    if (!await provider.validateUrl(uri)) {
      throw const FormatException('الرابط غير صالح أو غير مدعوم.');
    }

    final media = await provider.fetchMetadata(uri);
    final result = await policy.evaluate(uri: uri, media: media);
    if (!result.isAllowed) {
      throw StateError(result.reason ?? 'هذا المحتوى غير مسموح بتنزيله.');
    }

    return media;
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
