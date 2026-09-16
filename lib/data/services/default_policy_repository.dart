import '../../domain/entities/media_item.dart';
import '../../domain/repositories/policy_repository.dart';

class DefaultPolicyRepository implements PolicyRepository {
  const DefaultPolicyRepository();

  @override
  Future<PolicyResult> evaluate({
    required Uri uri,
    MediaItem? media,
  }) async {
    if (uri.scheme != 'http' && uri.scheme != 'https') {
      return const PolicyResult(
        decision: PolicyDecision.blocked,
        reason: 'نوع الرابط غير مدعوم.',
      );
    }

    if (uri.host.isEmpty) {
      return const PolicyResult(
        decision: PolicyDecision.blocked,
        reason: 'الرابط غير صالح.',
      );
    }

    return const PolicyResult(decision: PolicyDecision.allowed);
  }
}
