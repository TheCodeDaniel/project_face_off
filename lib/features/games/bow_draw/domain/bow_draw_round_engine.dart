import 'draw_outcome.dart';
import 'draw_rules.dart';
import 'draw_state.dart';

/// Bow & Draw's own round engine (multi-game plan Section 2.2). Pure,
/// synchronous domain logic driven entirely by explicit event methods
/// carrying server-authoritative timestamps — same shape as
/// `FaceOffRoundEngine`, so it's unit-testable with no camera, network, or
/// Firebase dependency, and describes a single round only.
///
/// Not run as internal `Timer`s — the caller ([BowDrawGameModule]) must
/// invoke [checkWindowElapsed] once enough wall-clock time has passed.
class BowDrawRoundEngine {
  BowDrawRoundEngine({required this.playerAId, required this.playerBId});

  final String playerAId;
  final String playerBId;

  DrawState _state = const NeutralDrawState();
  DrawState get state => _state;

  /// Reset for a fresh round (called by [BowDrawGameModule] before arming a
  /// new round) — unconditional, unlike [armRound], since the engine could
  /// be sitting in [DrawResultState] from the previous round when this is
  /// called.
  void reset() {
    _state = const NeutralDrawState();
  }

  /// Caller arms the round once both players are ready, with a
  /// server-generated [targetPower] (within [DrawRules.targetPowerMin]..
  /// [DrawRules.targetPowerMax]) already resolved and an absolute
  /// [windowEndsAt].
  void armRound(double targetPower, DateTime windowEndsAt) {
    if (_state is! NeutralDrawState) return;
    _state = ArmedDrawState(targetPower: targetPower, windowEndsAt: windowEndsAt);
  }

  /// A player's shot, carrying the draw [power] (0.0-1.0) they released at,
  /// server-timestamped.
  void onShoot(String playerId, double power) {
    final s = _state;
    if (s is! ArmedDrawState) return;

    final isHit = (power - s.targetPower).abs() <= DrawRules.hitTolerance;
    if (isHit) {
      _finalize(DrawOutcome(winnerId: playerId, reason: DrawEndReason.hit));
      return;
    }

    final missed = {...s.missed, playerId};
    if (missed.length == 2) {
      _finalize(const DrawOutcome(winnerId: null, reason: DrawEndReason.bothMissed));
    } else {
      _state = s.withMiss(playerId);
    }
  }

  /// Call once [DrawRules.shotWindow] has elapsed since the round was armed
  /// with no hit landed — draw if neither player ever shot, otherwise the
  /// [bothMissed] path already handled it via [onShoot].
  void checkWindowElapsed(DateTime now) {
    final s = _state;
    if (s is! ArmedDrawState) return;
    if (!now.isBefore(s.windowEndsAt)) {
      _finalize(const DrawOutcome(winnerId: null, reason: DrawEndReason.timeout));
    }
  }

  void _finalize(DrawOutcome outcome) {
    _state = DrawResultState(outcome: outcome);
  }
}
