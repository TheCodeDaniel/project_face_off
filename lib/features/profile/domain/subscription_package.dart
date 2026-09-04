enum BillingPeriod { monthly, annual }

/// One purchasable package inside the Face Off Plus offering — mirrors the
/// shape of a RevenueCat `Package` closely enough that swapping
/// [ProfileRepository.fetchOfferings] for a real RevenueCat-backed call is a
/// data-mapping change, not an API one (same reasoning as `AppUser` mirroring
/// Firebase Auth's `User` — see CLAUDE.md).
class SubscriptionPackage {
  const SubscriptionPackage({
    required this.id,
    required this.period,
    required this.title,
    required this.priceLabel,
    this.badge,
  });

  final String id;
  final BillingPeriod period;
  final String title;
  final String priceLabel;

  /// Short highlight shown on the package card, e.g. "Best value".
  final String? badge;
}
