import '../entities/media_item.dart';

enum PolicyDecision { allowed, blocked }

class PolicyResult {
  const PolicyResult({required this.decision, this.reason});

  final PolicyDecision decision;
  final String? reason;

  bool get isAllowed => decision == PolicyDecision.allowed;
}

abstract interface class PolicyRepository {
  Future<PolicyResult> evaluate({
    required Uri uri,
    MediaItem? media,
  });
}
