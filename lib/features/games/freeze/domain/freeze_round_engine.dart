import 'freeze_outcome.dart';
import 'freeze_rules.dart';
import 'freeze_state.dart';

/// Freeze's own round engine (multi-game plan Section 2.3). Pure,
/// synchronous domain logic driven entirely by explicit event methods
/// carrying server-authoritative timestamps — same shape as
/// `FaceOffRoundEngine`'s crack-detection handling, since "first player to
/// move loses, simultaneous moves draw" is structurally the same problem as
/// "first player to crack loses, simultaneous cracks draw."
class FreezeRoundEngine {
  FreezeRoundEngine({required this.playerAId, required this.playerBId});

  final String playerAId;
  final String playerBId;

  FreezeState _state = const BuildingFreezeState();
  FreezeState get state => _state;

  String _other(String playerId) => playerId == playerAId ? playerBId : playerAId;

  /// Reset for a fresh round (called by [FreezeGameModule] before scheduling
  /// the next build-up delay) — unconditional, unlike [callFreeze], since
  /// the engine could be sitting in [FreezeResultState] from the previous
  /// round when this is called.
  void reset() {
    _state = const BuildingFreezeState();
  }

  /// Caller calls the freeze once the build-up delay has elapsed, with a
  /// server-authoritative [windowEndsAt].
  void callFreeze(DateTime windowEndsAt) {
    if (_state is! BuildingFreezeState) return;
    _state = FrozenState(windowEndsAt: windowEndsAt);
  }

  /// A motion sample for [playerId] at [magnitude] — only samples during
  /// [FrozenState] (or a [ResolvingFreezeState] already pending from the
  /// other player) can ever matter; motion during [BuildingFreezeState] is
  /// expected and ignored entirely.
  void onMotionSample(String playerId, double magnitude, DateTime timestamp) {
    if (magnitude < FreezeRules.motionThreshold) return;

    final s = _state;
    if (s is FrozenState) {
      _state = ResolvingFreezeState(playerId: playerId, movedAt: timestamp);
      return;
    }
    if (s is ResolvingFreezeState && s.playerId != playerId) {
      final delta = timestamp.difference(s.movedAt).abs();
      if (delta <= FreezeRules.simultaneousMoveWindow) {
        _finalize(const FreezeOutcome(winnerId: null, reason: FreezeEndReason.simultaneousMove));
      }
      // Outside the jitter window, the first mover already lost — handled
      // by checkMoveWindowElapsed once that window passes.
    }
  }

  /// Call once [FreezeRules.simultaneousMoveWindow] has elapsed since a
  /// pending first move with no second move arriving — the mover loses.
  void checkMoveWindowElapsed(DateTime now) {
    final s = _state;
    if (s is! ResolvingFreezeState) return;
    if (!now.isBefore(s.movedAt.add(FreezeRules.simultaneousMoveWindow))) {
      _finalize(FreezeOutcome(winnerId: _other(s.playerId), reason: FreezeEndReason.moved));
    }
  }

  /// Call once [FreezeRules.freezeWindow] has elapsed with no motion ever
  /// detected — draw, nobody to penalize.
  void checkWindowElapsed(DateTime now) {
    final s = _state;
    if (s is! FrozenState) return;
    if (!now.isBefore(s.windowEndsAt)) {
      _finalize(const FreezeOutcome(winnerId: null, reason: FreezeEndReason.timeout));
    }
  }

  void _finalize(FreezeOutcome outcome) {
    _state = FreezeResultState(outcome: outcome);
  }
}
