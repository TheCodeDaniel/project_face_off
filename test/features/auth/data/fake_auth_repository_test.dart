import 'package:flutter_test/flutter_test.dart';
import 'package:project_face_off/features/auth/data/fake_auth_repository.dart';
import 'package:project_face_off/features/auth/domain/app_user.dart';

void main() {
  group('FakeAuthRepository', () {
    test('starts signed out', () {
      final repo = FakeAuthRepository();
      expect(repo.currentUser, isNull);
    });

    test('signInWithGoogle sets currentUser and emits on authStateChanges', () async {
      final repo = FakeAuthRepository();
      final states = <AppUser?>[];
      final sub = repo.authStateChanges().listen(states.add);

      final user = await repo.signInWithGoogle();

      expect(repo.currentUser, user);
      await Future<void>.delayed(Duration.zero);
      expect(states, contains(user));
      await sub.cancel();
    });

    test('signOut clears currentUser and emits null', () async {
      final repo = FakeAuthRepository();
      await repo.signInWithApple();
      expect(repo.currentUser, isNotNull);

      await repo.signOut();

      expect(repo.currentUser, isNull);
    });

    test('deleteAccount clears currentUser', () async {
      final repo = FakeAuthRepository();
      await repo.signInWithGoogle();

      await repo.deleteAccount();

      expect(repo.currentUser, isNull);
    });
  });
}
