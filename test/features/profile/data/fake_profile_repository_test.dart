import 'package:flutter_test/flutter_test.dart';
import 'package:project_face_off/features/profile/data/fake_profile_repository.dart';
import 'package:project_face_off/features/profile/domain/leaderboard_scope.dart';
import 'package:project_face_off/features/profile/domain/purchase_result.dart';
import 'package:project_face_off/features/profile/domain/subscription_tier.dart';

void main() {
  group('FakeProfileRepository', () {
    test('watchProfile uses the display name it was constructed with', () async {
      final repo = FakeProfileRepository(displayName: 'Ama');

      final profile = await repo.watchProfile().first;

      expect(profile.displayName, 'Ama');
    });

    test('is seeded with a leaderboard and cosmetics', () async {
      final repo = FakeProfileRepository(displayName: 'Ama');

      final leaderboard = await repo.watchLeaderboard(LeaderboardScope.global).first;
      final cosmetics = await repo.watchCosmetics().first;

      expect(leaderboard, isNotEmpty);
      expect(cosmetics, isNotEmpty);
      expect(cosmetics.where((c) => c.equipped), hasLength(1));
    });

    test('watchLeaderboard(friends) is a strict subset of watchLeaderboard(global)', () async {
      final repo = FakeProfileRepository(displayName: 'Ama');

      final global = await repo.watchLeaderboard(LeaderboardScope.global).first;
      final friends = await repo.watchLeaderboard(LeaderboardScope.friends).first;

      expect(friends, isNotEmpty);
      expect(friends.length, lessThan(global.length));
      expect(friends.every((f) => global.any((g) => g.name == f.name)), isTrue);
      // Matches FakeFriendsRepository's own seed: Kwesi/Naledi are friends
      // there, Tunde is only a pending incoming request, not yet a friend.
      expect(friends.any((e) => e.name == 'Tunde'), isFalse);
    });

    test('equipCosmetic swaps which owned cosmetic is equipped', () async {
      final repo = FakeProfileRepository(displayName: 'Ama');
      final cosmeticsBefore = await repo.watchCosmetics().first;
      final anotherOwned = cosmeticsBefore.firstWhere((c) => c.owned && !c.equipped);

      await repo.equipCosmetic(anotherOwned.id);

      final cosmeticsAfter = await repo.watchCosmetics().first;
      expect(cosmeticsAfter.where((c) => c.equipped).single.id, anotherOwned.id);
    });

    test('equipCosmetic on an unowned cosmetic is a no-op', () async {
      final repo = FakeProfileRepository(displayName: 'Ama');
      final cosmeticsBefore = await repo.watchCosmetics().first;
      final locked = cosmeticsBefore.firstWhere((c) => !c.owned);
      final equippedBefore = cosmeticsBefore.firstWhere((c) => c.equipped).id;

      await repo.equipCosmetic(locked.id);

      final cosmeticsAfter = await repo.watchCosmetics().first;
      expect(cosmeticsAfter.where((c) => c.equipped).single.id, equippedBefore);
    });

    test('starts on the free subscription tier', () async {
      final repo = FakeProfileRepository(displayName: 'Ama');

      final tier = await repo.watchSubscriptionTier().first;

      expect(tier, SubscriptionTier.free);
    });

    test('restorePurchases reports nothing to restore against the fake store', () async {
      final repo = FakeProfileRepository(displayName: 'Ama');

      final result = await repo.restorePurchases();

      expect(result.status, PurchaseResultStatus.nothingToRestore);
      expect(result.isSuccess, isFalse);
    });

    test('fetchOfferings returns a non-empty package catalog', () async {
      final repo = FakeProfileRepository(displayName: 'Ama');

      final packages = await repo.fetchOfferings();

      expect(packages, isNotEmpty);
    });

    test('purchasePackage upgrades the tier and emits it on watchSubscriptionTier', () async {
      final repo = FakeProfileRepository(displayName: 'Ama');
      final packages = await repo.fetchOfferings();
      // Subscribe (and let the async* generator forward to the broadcast
      // controller) before triggering the mutation — a broadcast stream
      // drops events with no listener, and .first only starts listening
      // once called. See the friends-repository test gotcha in CLAUDE.md.
      final tierUpdate = repo.watchSubscriptionTier().skip(1).first;

      final result = await repo.purchasePackage(packages.first.id);

      expect(result.status, PurchaseResultStatus.purchased);
      expect(result.isSuccess, isTrue);
      expect(await tierUpdate, SubscriptionTier.plus);
    });

    test('purchasePackage with an unknown id fails without changing the tier', () async {
      final repo = FakeProfileRepository(displayName: 'Ama');

      final result = await repo.purchasePackage('not_a_real_package');

      expect(result.status, PurchaseResultStatus.failed);
      expect(await repo.watchSubscriptionTier().first, SubscriptionTier.free);
    });
  });
}
