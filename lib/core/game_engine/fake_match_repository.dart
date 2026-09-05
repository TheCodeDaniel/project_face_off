import 'dart:async';

import 'match_repository.dart';
import 'match_result_record.dart';

/// In-memory [MatchRepository] used until a real Supabase project exists
/// (see CLAUDE.md). Persists for the app session's lifetime — not across
/// restarts, since there's no real database backing it yet.
class FakeMatchRepository implements MatchRepository {
  final _matches = <MatchResultRecord>[];
  final _controller = StreamController<List<MatchResultRecord>>.broadcast();

  @override
  Future<void> saveMatchResult(MatchResultRecord record) async {
    _matches.insert(0, record);
    _controller.add(List.unmodifiable(_matches));
  }

  @override
  Stream<List<MatchResultRecord>> watchRecentMatches() async* {
    yield List.unmodifiable(_matches);
    yield* _controller.stream;
  }
}
