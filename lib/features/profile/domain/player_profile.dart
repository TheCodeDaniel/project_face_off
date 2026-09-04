import 'package:flutter/foundation.dart';

import '../../../core/game_engine/game_pool.dart';
import 'game_stats.dart';

@immutable
class PlayerProfile {
  const PlayerProfile({
    required this.displayName,
    required this.tierLabel,
    required this.tierProgress,
    required this.winStreak,
    required this.totalMatches,
    required this.friendsCount,
    required this.winRatePercent,
    this.perGameStats = const {},
  });

  final String displayName;

  /// Named rank tier (Blueprint Section 1, dark rewards hub reference — e.g.
  /// "Iron II"). Lightweight for v1: cosmetic only, no gameplay effect.
  final String tierLabel;

  /// 0.0-1.0 progress within the current tier.
  final double tierProgress;

  /// Aggregate numbers across every game in the pool — what the Profile
  /// screen's main stat grid shows (multi-game plan Section 4.2: "the
  /// Profile screen's main stat grid still shows the aggregate numbers, no
  /// UI redesign needed there").
  final int winStreak;
  final int totalMatches;
  final int friendsCount;
  final int winRatePercent;

  /// Per-game breakdown, reachable from the stat grid via tap-through
  /// (`PerGameStatsSheet`) rather than a new top-level screen. A game with
  /// no entry here (not yet played) reads as "no matches yet" in that sheet.
  final Map<GameId, GameStats> perGameStats;
}
