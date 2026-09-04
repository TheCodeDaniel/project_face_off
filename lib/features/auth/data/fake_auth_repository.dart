import 'dart:async';

import '../domain/app_user.dart';
import '../domain/auth_repository.dart';

/// In-memory [AuthRepository] used until a real Firebase project exists.
/// Signing in always succeeds after a short simulated network delay, so the
/// onboarding → sign-in → shell flow is exercisable end-to-end in dev builds
/// and widget tests with no Firebase dependency. Swap for a
/// `FirebaseAuthRepository` once `flutterfire configure` has been run (see
/// CLAUDE.md).
class FakeAuthRepository implements AuthRepository {
  final _controller = StreamController<AppUser?>.broadcast();
  AppUser? _currentUser;

  @override
  Stream<AppUser?> authStateChanges() async* {
    yield _currentUser;
    yield* _controller.stream;
  }

  @override
  AppUser? get currentUser => _currentUser;

  @override
  Future<AppUser> signInWithGoogle() => _signIn('Google Player');

  @override
  Future<AppUser> signInWithApple() => _signIn('Apple Player');

  Future<AppUser> _signIn(String displayName) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    final user = AppUser(uid: 'fake-${DateTime.now().microsecondsSinceEpoch}', displayName: displayName);
    _currentUser = user;
    _controller.add(user);
    return user;
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
    _controller.add(null);
  }

  @override
  Future<void> deleteAccount() async {
    _currentUser = null;
    _controller.add(null);
  }
}
