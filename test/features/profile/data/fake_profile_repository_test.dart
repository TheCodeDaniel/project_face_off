import 'package:flutter_test/flutter_test.dart';
import 'package:project_face_off/features/profile/data/fake_profile_repository.dart';
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

      final leaderboard = await repo.watchLeaderboard().first;
      final cosmetics = await repo.watchCosmetics().first;

      expect(leaderboard, isNotEmpty);
      expect(cosmetics, isNotEmpty);
      expect(cosmetics.where((c) => c.equipped), hasLength(1));
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

    test('restorePurchases completes without throwing', () async {
      final repo = FakeProfileRepository(displayName: 'Ama');

      await expectLater(repo.restorePurchases(), completes);
    });
  });
}
