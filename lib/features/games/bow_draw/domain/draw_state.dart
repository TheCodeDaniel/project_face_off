import 'package:flutter/foundation.dart';

import 'draw_outcome.dart';

/// Bow & Draw's round state machine (multi-game plan Section 2.2), mirroring
/// Face Off's shape: a sealed hierarchy describing a single round only —
/// cross-round bookkeeping lives in `core/game_engine/match_controller.dart`.
@immutable
sealed class DrawState {
  const DrawState();
}

/// Both players ready, waiting for the target to appear.
final class NeutralDrawState extends DrawState {
  const NeutralDrawState();
}

/// The target is up (at [targetPower], a 0.0-1.0 draw strength a shot must
/// land near) and the shot window is open until [windowEndsAt]. [missed]
/// tracks who has already taken a shot and missed, without ending the round
/// — the other player can still land a clean hit and win outright.
final class ArmedDrawState extends DrawState {
  const ArmedDrawState({required this.targetPower, required this.windowEndsAt, this.missed = const {}});

  final double targetPower;
  final DateTime windowEndsAt;
  final Set<String> missed;

  ArmedDrawState withMiss(String playerId) =>
      ArmedDrawState(targetPower: targetPower, windowEndsAt: windowEndsAt, missed: {...missed, playerId});
}

/// Outcome displayed, brief pause before the next round.
final class DrawResultState extends DrawState {
  const DrawResultState({required this.outcome});

  final DrawOutcome outcome;
}
