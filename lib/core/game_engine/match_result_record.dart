import 'package:flutter/foundation.dart';

import 'game_pool.dart';

/// A concluded match's durable summary — what `MatchRepository` writes to
/// the Postgres `matches` table (game/UI/backend guideline Section 3) once a
/// match reaches `MatchCompleteMatchState`. The live event-by-event data
/// (round-by-round fire/dodge/crack, draw/release, etc.) stays in Realtime
/// DB and is never represented here — this is only the final summary.
@immutable
class MatchResultRecord {
  const MatchResultRecord({
    required this.matchId,
    required this.gameId,
    required this.opponentId,
    required this.opponentLabel,
    required this.iWon,
    required this.myScore,
    required this.opponentScore,
    required this.concludedAt,
  });

  final String matchId;
  final GameId gameId;

  /// The opponent's real identity — see `MatchController`'s own doc comment
  /// on why this is distinct from its internal `'me'`/`'opponent'` slot
  /// labels, which never leave the local round engine.
  final String opponentId;
  final String opponentLabel;

  /// `true` if the local player won, `false` if the opponent won, `null` for
  /// a draw/forfeit-less edge case.
  final bool? iWon;
  final int myScore;
  final int opponentScore;
  final DateTime concludedAt;
}
