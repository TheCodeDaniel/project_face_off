import 'dart:async';

import 'package:hugeicons/hugeicons.dart';

import '../../../core/widgets/podium_leaderboard.dart' show LeaderboardEntry;
import '../domain/cosmetic.dart';
import '../domain/player_profile.dart';
import '../domain/profile_repository.dart';
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
    ]);
  }

  final _cosmetics = <Cosmetic>[];
  final _cosmeticsController = StreamController<List<Cosmetic>>.broadcast();
  final _subscriptionController = StreamController<SubscriptionTier>.broadcast();
  final _tier = SubscriptionTier.free;
  final PlayerProfile _profile;

  static PlayerProfile _seedProfile(String displayName) => PlayerProfile(
    displayName: displayName,
    tierLabel: 'Iron II',
    tierProgress: 0.45,
    winStreak: 3,
    totalMatches: 12,
    friendsCount: 2,
    winRatePercent: 58,
  );

  static const _leaderboard = [
    LeaderboardEntry(name: 'Ama', score: 142),
    LeaderboardEntry(name: 'Kwesi', score: 128),
    LeaderboardEntry(name: 'Tunde', score: 97),
    LeaderboardEntry(name: 'Player', score: 84),
    LeaderboardEntry(name: 'Naledi', score: 71),
    LeaderboardEntry(name: 'Zara', score: 60),
  ];

  @override
  Stream<PlayerProfile> watchProfile() async* {
    yield _profile;
  }

  @override
  Stream<List<LeaderboardEntry>> watchLeaderboard() async* {
    yield _leaderboard;
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
  Future<void> restorePurchases() async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    // No real store to check — tier stays as-is.
  }
}
