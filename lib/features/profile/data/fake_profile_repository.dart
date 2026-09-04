import 'dart:async';

import 'package:hugeicons/hugeicons.dart';

import '../../../core/game_engine/game_pool.dart';
import '../../../core/widgets/podium_leaderboard.dart' show LeaderboardEntry;
import '../domain/cosmetic.dart';
import '../domain/game_stats.dart';
import '../domain/leaderboard_scope.dart';
import '../domain/player_profile.dart';
import '../domain/profile_repository.dart';
import '../domain/purchase_result.dart';
import '../domain/region.dart';
import '../domain/subscription_package.dart';
import '../domain/subscription_tier.dart';

/// In-memory [ProfileRepository] used until Firebase + RevenueCat exist (see
/// CLAUDE.md). `friendsCount` here is a static demo number rather than
/// derived from the friends feature — features never reach into each
/// other's internals (see engineering rule 1), so a real implementation
/// would read this off the player's own Firestore document, which the
/// friends feature keeps in sync, not off `FriendsRepository` directly.
class FakeProfileRepository implements ProfileRepository {
  FakeProfileRepository({required String displayName}) : _profile = _seedProfile(displayName) {
    _cosmetics.addAll([
      const Cosmetic(id: 'c1', name: 'Classic', icon: HugeIcons.strokeRoundedUserCircle02, owned: true, equipped: true),
      const Cosmetic(id: 'c2', name: 'Neon Glow', icon: HugeIcons.strokeRoundedSparkles, owned: true, equipped: false),
      const Cosmetic(id: 'c3', name: 'Champion', icon: HugeIcons.strokeRoundedCrown, owned: false, equipped: false),
      const Cosmetic(id: 'c4', name: 'Ghost', icon: HugeIcons.strokeRoundedUserCircle02, owned: false, equipped: false),
      // Game-specific, not universal (multi-game plan Section 5) — only
      // shows up as meaningful gear once Bow & Draw is actually playable.
      const Cosmetic(
        id: 'c5',
        name: 'Gold Arrows',
        icon: HugeIcons.strokeRoundedTarget03,
        owned: false,
        equipped: false,
        applicableGameId: GameId.bowDraw,
      ),
    ]);
  }

  final _cosmetics = <Cosmetic>[];
  final _cosmeticsController = StreamController<List<Cosmetic>>.broadcast();
  final _subscriptionController = StreamController<SubscriptionTier>.broadcast();
  var _tier = SubscriptionTier.free;
  final PlayerProfile _profile;

  static const _offerings = [
    SubscriptionPackage(id: 'plus_monthly', period: BillingPeriod.monthly, title: 'Monthly', priceLabel: '\$4.99/mo'),
    SubscriptionPackage(
      id: 'plus_annual',
      period: BillingPeriod.annual,
      title: 'Annual',
      priceLabel: '\$39.99/yr',
      badge: 'Save 33%',
    ),
  ];

  static PlayerProfile _seedProfile(String displayName) => PlayerProfile(
    displayName: displayName,
    tierLabel: 'Iron II',
    tierProgress: 0.45,
    winStreak: 3,
    totalMatches: 12,
    friendsCount: 2,
    winRatePercent: 58,
    region: Region.unitedStates,
    // Only Face Off has ever been playable (multi-game plan build order),
    // so it's the only game with a real match history so far — Bow & Draw
    // and Freeze simply have no entry, which the per-game stats sheet reads
    // as "no matches yet" rather than needing an explicit zero record.
    perGameStats: const {GameId.faceOff: GameStats(totalMatches: 12, winRatePercent: 58, winStreak: 3)},
  );

  static const _leaderboard = [
    LeaderboardEntry(name: 'Ama', score: 142),
    LeaderboardEntry(name: 'Kwesi', score: 128),
    LeaderboardEntry(name: 'Tunde', score: 97),
    LeaderboardEntry(name: 'Player', score: 84),
    LeaderboardEntry(name: 'Naledi', score: 71),
    LeaderboardEntry(name: 'Zara', score: 60),
  ];

  /// Which of the global seed's names are the local player's friends, for
  /// [LeaderboardScope.friends] — matches `FakeFriendsRepository`'s own seed
  /// (Kwesi, Naledi are friends there; Tunde is only a pending *incoming*
  /// request, not yet a friend, so deliberately excluded here too) plus the
  /// local player themself, so a friends-scoped board still shows where you
  /// personally rank. A real implementation resolves this server-side —
  /// this hardcoded overlap is a fake-data-only stand-in, not a read of
  /// `FriendsRepository` (see the class doc comment's `friendsCount` note).
  static const _friendNames = {'Kwesi', 'Naledi', 'Player'};

  /// Which region each seeded name is in, for [LeaderboardScope.regional] —
  /// same fake-data-only-overlap status as [_friendNames] above. 'Player'
  /// (the local player) is `Region.unitedStates`, matching
  /// [_seedProfile]'s own seeded `region`, so the two stay consistent.
  static const _entryRegions = {
    'Ama': Region.nigeria,
    'Kwesi': Region.ghana,
    'Tunde': Region.nigeria,
    'Player': Region.unitedStates,
    'Naledi': Region.southAfrica,
    'Zara': Region.unitedStates,
  };

  @override
  Stream<PlayerProfile> watchProfile() async* {
    yield _profile;
  }

  @override
  Stream<List<LeaderboardEntry>> watchLeaderboard(LeaderboardScope scope) async* {
    yield switch (scope) {
      LeaderboardScope.global => _leaderboard,
      LeaderboardScope.friends => _leaderboard.where((e) => _friendNames.contains(e.name)).toList(growable: false),
      LeaderboardScope.regional =>
        _leaderboard.where((e) => _entryRegions[e.name] == _profile.region).toList(growable: false),
    };
  }

  @override
  Stream<List<Cosmetic>> watchCosmetics() async* {
    yield List.unmodifiable(_cosmetics);
    yield* _cosmeticsController.stream;
  }

  @override
  Future<void> equipCosmetic(String cosmeticId) async {
    final matches = _cosmetics.where((c) => c.id == cosmeticId);
    if (matches.isEmpty || !matches.first.owned) return; // unknown or locked — no-op

    for (var i = 0; i < _cosmetics.length; i++) {
      final c = _cosmetics[i];
      if (!c.owned) continue;
      _cosmetics[i] = c.copyWith(equipped: c.id == cosmeticId);
    }
    _cosmeticsController.add(List.unmodifiable(_cosmetics));
  }

  @override
  Stream<SubscriptionTier> watchSubscriptionTier() async* {
    yield _tier;
    yield* _subscriptionController.stream;
  }

  @override
  Future<List<SubscriptionPackage>> fetchOfferings() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return _offerings;
  }

  @override
  Future<PurchaseResult> purchasePackage(String packageId) async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    final matches = _offerings.where((p) => p.id == packageId);
    if (matches.isEmpty) return const PurchaseResult(status: PurchaseResultStatus.failed, message: 'Unknown package.');

    _tier = SubscriptionTier.plus;
    _subscriptionController.add(_tier);
    return PurchaseResult(status: PurchaseResultStatus.purchased, message: matches.first.title);
  }

  @override
  Future<PurchaseResult> restorePurchases() async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    // No real store to check — tier stays as-is.
    return const PurchaseResult(status: PurchaseResultStatus.nothingToRestore);
  }
}
