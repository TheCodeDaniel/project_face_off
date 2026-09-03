import 'package:flutter/foundation.dart';

/// Minimal authenticated-user shape the rest of the app depends on. Field set
/// intentionally mirrors what Firebase Auth's `User` exposes so swapping
/// [FakeAuthRepository] for a real Firebase-backed implementation later is a
/// data-mapping change, not an API change (see CLAUDE.md).
@immutable
class AppUser {
  const AppUser({required this.uid, required this.displayName, this.photoUrl});

  final String uid;
  final String displayName;
  final String? photoUrl;
}
