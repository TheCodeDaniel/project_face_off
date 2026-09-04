import 'matchmaking_state.dart';

/// Matchmaking contract (master prompt Section 7). The real implementation
/// is a Firebase Realtime DB queue document, first-available match — no
/// skill-based matchmaking for v1 (explicitly deferred to v2 by the spec).
/// Realtime DB, not Postgres: this is ephemeral, high-frequency, small-
/// payload state, exactly what the hybrid backend guideline keeps on
/// Firebase (see CLAUDE.md's "Backend architecture" section). Needs a real
/// Firebase project first. [FakeMatchmakingRepository] backs this today so
/// the queue UI (searching/cancel/timeout/found) is fully buildable and
/// testable without one.
abstract class MatchmakingRepository {
  /// Emits the queue lifecycle for one matchmaking attempt: starts with
  /// [MatchmakingSearching], ends in exactly one of [MatchmakingFound] or
  /// [MatchmakingTimedOut] unless cancelled first (cancellation is the
  /// caller simply cancelling its stream subscription).
  Stream<MatchmakingState> joinQueue();
}
