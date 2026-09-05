import 'package:flutter/foundation.dart';

import 'game_pool.dart';
import 'match_round_outcome.dart';

/// [MatchController]'s own game-agnostic state — coarser than any single
/// game's internal round-phase state machine (Face Off's `RoundState`, say).
/// A game's own presentation layer renders the fine-grained detail while
/// this state drives the shared match chrome: score header, recap toast,
/// and the final result screen.
@immutable
sealed class MatchState {
  const MatchState();
}

/// No match has been started yet (before `MatchController.startMatch` is
/// first called) — a brief initial value only, same role the old
/// `DuelController.build()`'s eager engine construction played.
final class NoActiveMatchState extends MatchState {
  const NoActiveMatchState();
}

/// A round of [gameId] is currently live — the active [GameModule]'s own
/// round-phase state drives what's actually on screen.
final class PlayingRoundMatchState extends MatchState {
  const PlayingRoundMatchState({required this.gameId});

  final GameId gameId;
}

/// A round just resolved; [outcome]/[scores]/[roundNumber] reflect it while
/// the recap plays, before the next round (or [MatchCompleteMatchState])
/// begins.
final class RoundRecapMatchState extends MatchState {
  const RoundRecapMatchState({required this.outcome, required this.scores, required this.roundNumber});

  final MatchRoundOutcome outcome;
  final Map<String, int> scores;
  final int roundNumber;
}

/// Best-of-5 concluded, any game.
final class MatchCompleteMatchState extends MatchState {
  const MatchCompleteMatchState({required this.winnerId, required this.scores});

  final String? winnerId;
  final Map<String, int> scores;
}
