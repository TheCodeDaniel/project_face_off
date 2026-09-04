import 'package:flutter/foundation.dart';

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
  });

  final String displayName;

  /// Named rank tier (Blueprint Section 1, dark rewards hub reference — e.g.
  /// "Iron II"). Lightweight for v1: cosmetic only, no gameplay effect.
  final String tierLabel;

  /// 0.0-1.0 progress within the current tier.
  final double tierProgress;

  final int winStreak;
  final int totalMatches;
  final int friendsCount;
  final int winRatePercent;
}
