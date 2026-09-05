import 'package:flutter/foundation.dart';

import 'freeze_outcome.dart';

/// Freeze's round state machine (multi-game plan Section 2.3), mirroring
/// Face Off's shape: a sealed hierarchy describing a single round only.
@immutable
sealed class FreezeState {
  const FreezeState();
}

/// Music/tension builds, players move loosely — no penalty for motion here.
final class BuildingFreezeState extends FreezeState {
  const BuildingFreezeState();
}

/// The freeze cue just fired — the window is open until [windowEndsAt]. Any
/// motion sample past the threshold during this phase counts.
final class FrozenState extends FreezeState {
  const FrozenState({required this.windowEndsAt});

  final DateTime windowEndsAt;
}

/// A first move was detected at [movedAt] by [playerId] — held briefly to
/// see if the other player also moves within the simultaneous-move jitter
/// window (same pattern as Face Off's pending-crack window), before
/// finalizing.
final class ResolvingFreezeState extends FreezeState {
  const ResolvingFreezeState({required this.playerId, required this.movedAt});

  final String playerId;
  final DateTime movedAt;
}

/// Outcome displayed, brief pause before the next round.
final class FreezeResultState extends FreezeState {
  const FreezeResultState({required this.outcome});

  final FreezeOutcome outcome;
}
