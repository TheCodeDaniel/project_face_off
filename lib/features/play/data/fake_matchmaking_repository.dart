import 'dart:async';
import 'dart:math';

import '../domain/matchmaking_repository.dart';
import '../domain/matchmaking_state.dart';

/// In-memory [MatchmakingRepository] used until a real Firebase queue exists
/// (see CLAUDE.md). Pairs the player with a fake opponent after a short
/// random delay; occasionally simulates the "no opponent found" timeout path
/// (compressed to a couple of seconds here, not the real 20s, purely so the
/// UI's timeout state is exercised in dev builds without forcing it
/// manually) so both outcomes get real screen time during development.
class FakeMatchmakingRepository implements MatchmakingRepository {
  static const _opponentNames = ['Ama', 'Kwesi', 'Naledi', 'Tunde', 'Zara'];
  static const _timeoutChance = 1 / 6;

  @override
  Stream<MatchmakingState> joinQueue() async* {
    yield const MatchmakingSearching();

    final random = Random();
    await Future<void>.delayed(Duration(milliseconds: 1200 + random.nextInt(2500)));

    if (random.nextDouble() < _timeoutChance) {
      yield const MatchmakingTimedOut();
      return;
    }

    final opponentName = _opponentNames[random.nextInt(_opponentNames.length)];
    yield MatchmakingFound(
      matchId: 'fake-match-${DateTime.now().microsecondsSinceEpoch}',
      opponentId: 'bot-${opponentName.toLowerCase()}',
      opponentName: opponentName,
    );
  }
}
