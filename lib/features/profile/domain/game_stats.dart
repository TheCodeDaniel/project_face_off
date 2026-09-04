import 'package:flutter/foundation.dart';

/// Per-game slice of a player's stats (multi-game plan Section 4.2) — same
/// three numbers as the aggregate on [PlayerProfile], just scoped to one
/// game. Kept deliberately simple (no per-game leaderboard, no extra
/// metrics) per the plan's own "don't design a whole per-game stats
/// dashboard now" instruction.
@immutable
class GameStats {
  const GameStats({required this.totalMatches, required this.winRatePercent, required this.winStreak});

  final int totalMatches;
  final int winRatePercent;
  final int winStreak;
}
