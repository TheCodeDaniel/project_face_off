/// The opponent's answer to a rematch request.
enum RematchAnswer { accepted, declined }

/// Rematch-request contract (post-match flow plan Section 3/5). The real
/// implementation is a lightweight Realtime DB node,
/// `/rematchRequests/{matchId}` (requester id, target id, server
/// timestamp), cleared on accept/decline/timeout — ephemeral, high-
/// frequency, small-payload state, so it stays on Realtime DB rather than
/// Postgres, same reasoning as the match event log (see CLAUDE.md's hybrid-
/// backend section). Needs a real Firebase project first.
/// [FakeRematchRepository] backs this today.
abstract class RematchRepository {
  /// Sends a rematch request for [matchId] to [opponentId]. Emits exactly
  /// one [RematchAnswer] if the opponent responds — never emits at all for
  /// a timeout, since that's [RematchController]'s own local timer's job,
  /// not something the opponent explicitly does.
  Stream<RematchAnswer> sendRequest({required String matchId, required String opponentId});
}
