import 'app_user.dart';

/// Auth contract the rest of the app depends on. The real implementation
/// (`firebase_auth` + `google_sign_in` + `sign_in_with_apple`, per master
/// prompt Section 6) needs `flutterfire configure` run against a real
/// Firebase project first — see CLAUDE.md "What's stubbed pending your
/// credentials". Until then, [FakeAuthRepository] backs this interface so
/// the onboarding/sign-in UI and shell-gating logic are fully buildable and
/// testable today.
abstract class AuthRepository {
  Stream<AppUser?> authStateChanges();

  AppUser? get currentUser;

  Future<AppUser> signInWithGoogle();

  Future<AppUser> signInWithApple();

  Future<void> signOut();

  /// Deletes the account (master prompt Section 10 — App Store requires real
  /// account deletion, not just sign-out). The real implementation also
  /// deletes the Firestore profile document; this contract only covers the
  /// auth-provider side.
  Future<void> deleteAccount();
}
