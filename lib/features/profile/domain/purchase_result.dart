enum PurchaseResultStatus { purchased, restored, nothingToRestore, cancelled, failed }

/// Outcome of a [ProfileRepository.purchasePackage] or `restorePurchases`
/// call — richer than a bare `Future<void>` so the paywall/subscription UI
/// can tell "you're already subscribed, nothing to restore" apart from an
/// actual failure, rather than collapsing both into the same silent success.
class PurchaseResult {
  const PurchaseResult({required this.status, this.message});

  final PurchaseResultStatus status;
  final String? message;

  bool get isSuccess => status == PurchaseResultStatus.purchased || status == PurchaseResultStatus.restored;
}
