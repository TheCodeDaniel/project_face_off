import 'package:flutter/foundation.dart';

import 'round_outcome.dart';

/// Explicit round state machine (master prompt Section 8.3) — modeled as a
/// sealed hierarchy, not ad-hoc booleans, so exhaustiveness is checked at
/// compile time by every `switch` over it.
@immutable
sealed class RoundState {
  const RoundState();
}

/// Both players calm, waiting for the cue window. [neutralConfirmed] tracks
/// which player ids have confirmed a neutral face so far.
final class NeutralRoundState extends RoundState {
  const NeutralRoundState({this.neutralConfirmed = const {}});

  final Set<String> neutralConfirmed;
}

/// Countdown to cue has started, hidden from the player. [cueFireAt] is the
/// server-authoritative timestamp the cue will fire at.
final class CueArmedRoundState extends RoundState {
  const CueArmedRoundState({required this.cueFireAt});

  final DateTime cueFireAt;
}

/// The fire/dodge window is open. [attackerId]/[attackerFireAt] are set once
/// a player's fire gesture has been received.
final class CueFiredRoundState extends RoundState {
  const CueFiredRoundState({required this.cueFiredAt, this.attackerId, this.attackerFireAt});

  final DateTime cueFiredAt;
  final String? attackerId;
  final DateTime? attackerFireAt;

  CueFiredRoundState withAttacker(String id, DateTime at) =>
      CueFiredRoundState(cueFiredAt: cueFiredAt, attackerId: id, attackerFireAt: at);

  CueFiredRoundState clearAttacker() => CueFiredRoundState(cueFiredAt: cueFiredAt);
}

/// Inputs received, computing outcome — no user input accepted in this phase.
final class ResolvingRoundState extends RoundState {
  const ResolvingRoundState();
}

/// Outcome displayed, brief pause before the next round (or match end).
/// Cross-round bookkeeping (running score, whether the match itself is over)
/// lives one level up, in `MatchController`'s `MatchState` — this state
/// machine only ever describes a single round.
final class RoundResultRoundState extends RoundState {
  const RoundResultRoundState({required this.outcome});

  final RoundOutcome outcome;
}
