import '../../../core/widgets/podium_leaderboard.dart' show LeaderboardEntry;
import 'cosmetic.dart';
import 'leaderboard_scope.dart';
import 'player_profile.dart';
import 'purchase_result.dart';
import 'subscription_package.dart';
import 'subscription_tier.dart';

/// Profile contract (master prompt Section 10). The real implementation is
/// Postgres-backed (via Supabase) for profile/leaderboard/cosmetics — the
/// `users`/`user_game_stats`/`cosmetics_owned` tables, see
/// `supabase/migrations/` — and RevenueCat-backed for subscription state
/// (`subscriptions_cache`, kept in sync via RevenueCat webhook, never
/// trusting client-reported purchase state directly). This corrects the
/// original master prompt's Firestore plan — see the game/UI/backend
/// guideline's "hybrid split" section in CLAUDE.md for why. Needs a real
/// Supabase project + RevenueCat keys first. [FakeProfileRepository] backs this today.
///
/// Leaderboard ranking metric is **total round wins** (not match wins) —
/// documented explicitly per the master prompt's own instruction not to
/// leave the scoring metric implicit.
abstract class ProfileRepository {
  Stream<PlayerProfile> watchProfile();

  /// [scope] narrows who's ranked — see [LeaderboardScope]'s own doc
  /// comment. The real implementation resolves Regional/Friends
  /// server-side (Regional by the player's stored `Region`, Friends by
  /// joining against their actual friends list) — never a client-side read
  /// of `FriendsRepository` (engineering rule 1: features never reach into
  /// each other's internals).
  Stream<List<LeaderboardEntry>> watchLeaderboard(LeaderboardScope scope);

  Stream<List<Cosmetic>> watchCosmetics();

  Future<void> equipCosmetic(String cosmeticId);

  Stream<SubscriptionTier> watchSubscriptionTier();

  /// Face Off Plus's purchasable packages — the RevenueCat "Offering" once
  /// that's wired up. The fake returns a static monthly/annual pair so the
  /// paywall's full package-picker → purchase UI is exercisable today.
  Future<List<SubscriptionPackage>> fetchOfferings();

  /// Buys [packageId]. On success, [watchSubscriptionTier] emits the new
  /// tier — the paywall/subscription UI never needs to poll for it.
  Future<PurchaseResult> purchasePackage(String packageId);

  /// Required by App Store guidelines for any app with paid content —
  /// re-checks the store for prior purchases. The fake always resolves to
  /// "nothing to restore" since there's no real store to check against.
  Future<PurchaseResult> restorePurchases();
}
