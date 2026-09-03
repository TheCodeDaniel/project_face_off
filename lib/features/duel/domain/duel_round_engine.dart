import 'round_outcome.dart';
import 'round_rules.dart';
import 'round_state.dart';

/// The duel game engine (master prompt Section 8). Pure, synchronous domain
/// logic driven entirely by explicit event methods carrying
/// server-authoritative timestamps — never touches `DateTime.now()` or raw
/// blendshape numbers itself, which is what makes it unit-testable with no
/// camera, network, or Firebase dependency (feed it fake events; see
/// `test/features/duel/domain/duel_round_engine_test.dart`).
///
/// Time-boxed windows (dodge window, simultaneous-crack window, round
/// timeout) are *not* run as internal `Timer`s — the caller (duel
/// presentation/data layer, backed by real signaling timestamps) must invoke
/// [checkDodgeWindowElapsed]/[checkCrackWindowElapsed]/[checkRoundTimeout]
/// once enough wall-clock time has passed. This keeps the engine free of
/// hidden async and trivially testable synchronously.
class DuelRoundEngine {
  DuelRoundEngine({required this.playerAId, required this.playerBId}) : scores = {playerAId: 0, playerBId: 0};

  final String playerAId;
  final String playerBId;
  final Map<String, int> scores;

  RoundState _state = const NeutralRoundState();
  RoundState get state => _state;

  ({String playerId, DateTime timestamp})? _pendingCrack;

  String _other(String playerId) => playerId == playerAId ? playerBId : playerAId;

  bool get _roundIsOpen => _state is NeutralRoundState || _state is CueArmedRoundState || _state is CueFiredRoundState;

  /// Reset for a fresh round (called after [RoundResultRoundState] recap, or
  /// to start Round 1 after the DuelVsTransition).
  void startNeutralPhase() {
    _pendingCrack = null;
    _state = const NeutralRoundState();
  }

  void playerReachedNeutral(String playerId) {
    final s = _state;
    if (s is! NeutralRoundState) return;
    final confirmed = {...s.neutralConfirmed, playerId};
    _state = NeutralRoundState(neutralConfirmed: confirmed);
  }

  bool get bothNeutral {
    final s = _state;
    return s is NeutralRoundState && s.neutralConfirmed.length == 2;
  }

  /// Caller arms the cue once [bothNeutral] is true, with a server-generated
  /// fire delay of [RoundRules.cueDelayMin]..[RoundRules.cueDelayMax] already
  /// resolved into an absolute [cueFireAt].
  void armCue(DateTime cueFireAt) {
    if (_state is! NeutralRoundState) return;
    _state = CueArmedRoundState(cueFireAt: cueFireAt);
  }

  void fireCue(DateTime authoritativeFireTimestamp) {
    if (_state is! CueArmedRoundState) return;
    _state = CueFiredRoundState(cueFiredAt: authoritativeFireTimestamp);
  }

  /// A player's "fire" (mouth-open) gesture, server-timestamped.
  void onFireGesture(String playerId, DateTime serverTimestamp) {
    final s = _state;
    if (s is CueArmedRoundState) {
      if (serverTimestamp.isBefore(s.cueFireAt)) {
        _finalize(RoundOutcome(winnerId: _other(playerId), reason: RoundEndReason.falseStart));
      }
      return;
    }
    if (s is CueFiredRoundState && s.attackerId == null) {
      _state = s.withAttacker(playerId, serverTimestamp);
    }
  }

  /// A player's "dodge" (eyebrow-raise) gesture, server-timestamped.
  void onDodgeGesture(String playerId, DateTime serverTimestamp) {
    final s = _state;
    if (s is! CueFiredRoundState || s.attackerId == null) return;
    if (playerId == s.attackerId) return;

    final withinWindow = !serverTimestamp.isAfter(s.attackerFireAt!.add(RoundRules.dodgeWindow));
    if (!withinWindow) return;

    if (RoundRules.dodgeEndsRoundOnSuccess) {
      _finalize(RoundOutcome(winnerId: playerId, reason: RoundEndReason.dodged));
    } else {
      _state = s.clearAttacker();
    }
  }

  /// Call once [RoundRules.dodgeWindow] has elapsed since the attacker's fire
  /// with no valid dodge — finalizes the round as an attacker win.
  void checkDodgeWindowElapsed(DateTime now) {
    final s = _state;
    if (s is! CueFiredRoundState || s.attackerId == null) return;
    if (!now.isBefore(s.attackerFireAt!.add(RoundRules.dodgeWindow))) {
      _finalize(RoundOutcome(winnerId: s.attackerId, reason: RoundEndReason.firedFirst));
    }
  }

  /// Call once [RoundRules.roundTimeout] has elapsed since cue-fire with no
  /// attacker resolved.
  void checkRoundTimeout(DateTime now) {
    final s = _state;
    if (s is! CueFiredRoundState || s.attackerId != null) return;
    if (!now.isBefore(s.cueFiredAt.add(RoundRules.roundTimeout))) {
      _finalize(const RoundOutcome(winnerId: null, reason: RoundEndReason.timeout));
    }
  }

  /// Crack detection (master prompt 8.4): runs across all open phases and
  /// overrides everything. The instant a crack is detected the round moves
  /// to resolving; a same-window crack from the other player produces a
  /// draw, checked via [checkCrackWindowElapsed] once the window has passed.
  void onCrackGesture(String playerId, DateTime serverTimestamp) {
    if (!_roundIsOpen && _pendingCrack == null) return;

    final pending = _pendingCrack;
    if (pending == null) {
      _pendingCrack = (playerId: playerId, timestamp: serverTimestamp);
      _state = const ResolvingRoundState();
      return;
    }
    if (pending.playerId == playerId) return;

    final delta = serverTimestamp.difference(pending.timestamp).abs();
    if (delta <= RoundRules.simultaneousCrackWindow) {
      _finalize(const RoundOutcome(winnerId: null, reason: RoundEndReason.simultaneousCrack));
    }
  }

  /// Call once [RoundRules.simultaneousCrackWindow] has elapsed since the
  /// first crack with no second crack arriving — finalizes a single-crack
  /// loss for the cracking player.
  void checkCrackWindowElapsed(DateTime now) {
    final pending = _pendingCrack;
    if (pending == null || _state is! ResolvingRoundState) return;
    if (!now.isBefore(pending.timestamp.add(RoundRules.simultaneousCrackWindow))) {
      _finalize(RoundOutcome(winnerId: _other(pending.playerId), reason: RoundEndReason.cracked));
    }
  }

  void _finalize(RoundOutcome outcome) {
    _pendingCrack = null;
    final winnerId = outcome.winnerId;
    if (winnerId != null) {
      scores[winnerId] = (scores[winnerId] ?? 0) + 1;
    }
    _state = RoundResultRoundState(outcome: outcome, scores: Map.unmodifiable(scores));
  }

  /// Advance out of [RoundResultRoundState] after the recap: to the next
  /// round's neutral phase, or to [MatchResultRoundState] if a player has
  /// reached [RoundRules.roundsToWinMatch].
  void advanceAfterRecap() {
    if (_state is! RoundResultRoundState) return;
    final winner = scores.entries.where((e) => e.value >= RoundRules.roundsToWinMatch).firstOrNull;
    if (winner != null) {
      _state = MatchResultRoundState(winnerId: winner.key, scores: Map.unmodifiable(scores));
    } else {
      startNeutralPhase();
    }
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
