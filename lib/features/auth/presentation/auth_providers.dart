import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/fake_auth_repository.dart';
import '../domain/app_user.dart';
import '../domain/auth_repository.dart';

/// Overridden with a real Firebase-backed implementation once
/// `flutterfire configure` has been run — see CLAUDE.md.
final authRepositoryProvider = Provider<AuthRepository>((ref) => FakeAuthRepository());

final authStateProvider = StreamProvider<AppUser?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});
