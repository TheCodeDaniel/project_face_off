import 'dart:async';
import 'dart:math';

import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/game_engine/game_module.dart';
import '../../../../core/game_engine/landmarker_type.dart';
import '../../../../core/game_engine/match_round_outcome.dart';
import 'bow_draw_round_engine.dart';
import 'draw_outcome.dart';
import 'draw_rules.dart';
import 'draw_state.dart';

/// Bow & Draw's [GameModule] — mirrors `FaceOffGameModule`'s shape exactly:
/// wraps [BowDrawRoundEngine], owns the round-window `Timer`, and is a
/// [ChangeNotifier] so the screen can listen to [drawState] directly while
/// `MatchController` only ever sees the coarser [roundOutcomes] stream.
///
/// **No camera exists yet** — both sides' shots are driven manually via
/// [triggerShoot] from a dev gesture-controls panel, standing in for the
/// real Hand Landmarker output (draw distance -> power, open-hand snap ->
/// release) until that's built.
class BowDrawGameModule extends ChangeNotifier implements GameModule {
  BowDrawGameModule({required this.playerAId, required this.playerBId})
    : _engine = BowDrawRoundEngine(playerAId: playerAId, playerBId: playerBId);

  final String playerAId;
  final String playerBId;
  final _random = Random();
  final _outcomeController = StreamController<MatchRoundOutcome>.broadcast();

  final BowDrawRoundEngine _engine;
  Timer? _windowTimer;

  /// Live draw-power-in-progress per player, driven by [DrawUpdate] events
  /// from the real hand-gesture pipeline (game/UI/backend guideline Section
  /// 2) once wired up — for now, by the dev-harness drag control. Kept
  /// outside [BowDrawRoundEngine]'s own state deliberately: this is purely a
  /// presentation value the bow rig's draw-back animation reads (the single
  /// most important visual feedback loop per the guideline), not something
  /// that affects round-outcome logic, which only ever sees a shot's final
  /// released power via [triggerShoot].
  final _livePower = <String, double>{};
  Map<String, double> get livePower => Map.unmodifiable(_livePower);

  /// Guards against re-emitting an outcome for a round that already
  /// resolved — the engine's state stays [DrawResultState] until the next
  /// [startRound], so a stray extra [triggerShoot] call in that window
  /// (e.g. a late dev-harness tap) would otherwise walk straight through
  /// [_resolveIfNeeded]'s "is the round resolved" check a second time and
  /// push a duplicate [MatchRoundOutcome], double-counting the score on
  /// `MatchController`.
  bool _emittedThisRound = false;

  @override
  String get id => 'bow_draw';

  @override
  String get displayName => 'Bow & Draw';

  @override
  Set<LandmarkerType> get requiredLandmarkers => const {LandmarkerType.hand};

  @override
  Stream<MatchRoundOutcome> get roundOutcomes => _outcomeController.stream;

  DrawState get drawState => _engine.state;

  @override
  void startRound() {
    _cancelTimers();
    _engine.reset();
    _emittedThisRound = false;
    _livePower.clear();
    final targetPower =
        DrawRules.targetPowerMin + _random.nextDouble() * (DrawRules.targetPowerMax - DrawRules.targetPowerMin);
    final windowEndsAt = clock.now().add(DrawRules.shotWindow);
    _engine.armRound(targetPower, windowEndsAt);
    notifyListeners();

    _windowTimer = Timer(DrawRules.shotWindow, () {
      _engine.checkWindowElapsed(clock.now());
      _resolveIfNeeded();
    });
  }

  @override
  void resetRound() => _cancelTimers();

  void triggerShoot(String playerId, double power) {
    _livePower[playerId] = 0;
    _engine.onShoot(playerId, power);
    _resolveIfNeeded();
  }

  /// Continuous draw-power update (`DrawUpdate.power`, 0.0-1.0) — never
  /// resolves the shot itself, just what the bow rig's draw-back animation
  /// renders while a player is mid-pull.
  void updateDrawPower(String playerId, double power) {
    _livePower[playerId] = power;
    notifyListeners();
  }

  void _resolveIfNeeded() {
    notifyListeners();
    final s = _engine.state;
    if (s is! DrawResultState || _emittedThisRound) return;
    _emittedThisRound = true;
    _cancelTimers();
    _outcomeController.add(MatchRoundOutcome(winnerId: s.outcome.winnerId, reasonCode: _reasonCode(s.outcome.reason)));
  }

  String _reasonCode(DrawEndReason reason) => switch (reason) {
    DrawEndReason.hit => 'hit',
    DrawEndReason.bothMissed => 'both_missed',
    DrawEndReason.timeout => 'timeout',
  };

  void _cancelTimers() => _windowTimer?.cancel();

  @override
  void dispose() {
    _cancelTimers();
    _outcomeController.close();
    super.dispose();
  }
}
