import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/podium_leaderboard.dart' show LeaderboardEntry;
import '../../auth/presentation/auth_providers.dart';
import '../data/fake_profile_repository.dart';
import '../domain/cosmetic.dart';
import '../domain/leaderboard_scope.dart';
import '../domain/player_profile.dart';
import '../domain/profile_repository.dart';
import '../domain/subscription_package.dart';
import '../domain/subscription_tier.dart';

/// Overridden with real Firebase/RevenueCat-backed implementations once both
/// exist — see CLAUDE.md. The fake is seeded with the signed-in player's own
/// display name so the demo reads coherently end-to-end.
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final displayName = ref.watch(authStateProvider).valueOrNull?.displayName ?? 'Player';
  return FakeProfileRepository(displayName: displayName);
});

final playerProfileProvider = StreamProvider<PlayerProfile>((ref) {
  return ref.watch(profileRepositoryProvider).watchProfile();
});

/// Which scope the Leaderboard screen currently has selected — a plain
/// `StateProvider` (small local UI state, not async) that the scope
/// selector writes to and `leaderboardProvider` reads as its `.family` arg.
final leaderboardScopeProvider = StateProvider<LeaderboardScope>((ref) => LeaderboardScope.global);

final leaderboardProvider = StreamProvider.family<List<LeaderboardEntry>, LeaderboardScope>((ref, scope) {
  return ref.watch(profileRepositoryProvider).watchLeaderboard(scope);
});

final cosmeticsProvider = StreamProvider<List<Cosmetic>>((ref) {
  return ref.watch(profileRepositoryProvider).watchCosmetics();
});

final subscriptionTierProvider = StreamProvider<SubscriptionTier>((ref) {
  return ref.watch(profileRepositoryProvider).watchSubscriptionTier();
});

/// The Face Off Plus paywall's package picker — a `FutureProvider` rather
/// than a stream since the offering catalog doesn't change while the
/// paywall is open. Purchasing/restoring are one-shot actions the UI calls
/// directly on `profileRepositoryProvider`, not modeled as providers.
final subscriptionOfferingsProvider = FutureProvider<List<SubscriptionPackage>>((ref) {
  return ref.watch(profileRepositoryProvider).fetchOfferings();
});
