import 'match_result_record.dart';

/// Durable match-history contract (game/UI/backend guideline Section 3). The
/// real implementation writes to the Postgres `matches` table (via Supabase
/// — see `supabase/migrations/`) once a match concludes; this is the
/// documented trigger point the master prompt's Section 8.4 MatchResult
/// phase called out but never wired up. [FakeMatchRepository] backs this
/// today, in-memory, so match history has somewhere real to persist to
/// (for the session's lifetime) without a live Supabase project.
abstract class MatchRepository {
  Future<void> saveMatchResult(MatchResultRecord record);

  /// Most recent matches for the local player, most recent first — what
  /// `MatchHistoryTeaser` (Play tab) reads from.
  Stream<List<MatchResultRecord>> watchRecentMatches();
}
