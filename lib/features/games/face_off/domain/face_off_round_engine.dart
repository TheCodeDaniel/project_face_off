import 'round_outcome.dart';
import 'round_rules.dart';
import 'round_state.dart';

/// Face Off's own round engine (master prompt Section 8). Pure, synchronous
/// domain logic driven entirely by explicit event methods carrying
/// server-authoritative timestamps — never touches `DateTime.now()` or raw
/// blendshape numbers itself, which is what makes it unit-testable with no
/// camera, network, or Firebase dependency (feed it fake events; see
/// `test/features/games/face_off/domain/face_off_round_engine_test.dart`).
///
/// Describes a single round only — cross-round bookkeeping (running score,
/// best-of-5 completion, forfeiting the whole match) is
/// `core/game_engine/match_controller.dart`'s job now, not this engine's
/// (multi-game plan Section 3.2). `FaceOffGameModule` wraps this engine and
/// is what `MatchController` actually talks to.
///
/// Time-boxed windows (dodge window, simultaneous-crack window, round
/// timeout) are *not* run as internal `Timer`s — the caller
/// ([FaceOffGameModule], backed by real signaling timestamps eventually)
/// must invoke [checkDodgeWindowElapsed]/[checkCrackWindowElapsed]/
/// [checkRoundTimeout] once enough wall-clock time has passed. This keeps
/// the engine free of hidden async and trivially testable synchronously.
class FaceOffRoundEngine {
  FaceOffRoundEngine({required this.playerAId, required this.playerBId});

  final String playerAId;
  final String playerBId;

  RoundState _state = const NeutralRoundState();
  RoundState get state => _state;

  ({String playerId, DateTime timestamp})? _pendingCrack;

  String _other(String playerId) => playerId == playerAId ? playerBId : playerAId;

  bool get _roundIsOpen => _state is NeutralRoundState || _state is CueArmedRoundState || _state is CueFiredRoundState;

  /// Reset for a fresh round (called by [FaceOffGameModule] before arming a
  /// new round, whether that's Round 1 after the DuelVsTransition or any
  /// later round after a recap).
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
    _state = RoundResultRoundState(outcome: outcome);
  }
}
