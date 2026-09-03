import '../../../core/widgets/podium_leaderboard.dart' show LeaderboardEntry;
import 'cosmetic.dart';
import 'player_profile.dart';
import 'subscription_tier.dart';

/// Profile contract (master prompt Section 10). The real implementation is
/// Firestore-backed for profile/leaderboard/cosmetics and RevenueCat-backed
/// for subscription state — needs a real Firebase project + RevenueCat keys
/// first; see CLAUDE.md. [FakeProfileRepository] backs this today.
///
/// Leaderboard ranking metric is **total round wins** (not match wins) —
/// documented explicitly per the master prompt's own instruction not to
/// leave the scoring metric implicit.
abstract class ProfileRepository {
  Stream<PlayerProfile> watchProfile();

  Stream<List<LeaderboardEntry>> watchLeaderboard();

  Stream<List<Cosmetic>> watchCosmetics();

  Future<void> equipCosmetic(String cosmeticId);

  Stream<SubscriptionTier> watchSubscriptionTier();

  /// Required by App Store guidelines for any app with paid content —
  /// re-checks the store for prior purchases. The fake always resolves to
  /// "nothing to restore" since there's no real store to check against.
  Future<void> restorePurchases();
}
