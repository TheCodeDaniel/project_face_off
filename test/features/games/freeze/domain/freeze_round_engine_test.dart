import 'package:flutter_test/flutter_test.dart';
import 'package:project_face_off/features/games/freeze/domain/freeze_outcome.dart';
import 'package:project_face_off/features/games/freeze/domain/freeze_round_engine.dart';
import 'package:project_face_off/features/games/freeze/domain/freeze_state.dart';

void main() {
  const playerA = 'playerA';
  const playerB = 'playerB';
  final t0 = DateTime.utc(2026, 1, 1);
  final windowEndsAt = t0.add(const Duration(seconds: 3));

  FreezeRoundEngine frozenEngine() {
    final e = FreezeRoundEngine(playerAId: playerA, playerBId: playerB);
    e.callFreeze(windowEndsAt);
    return e;
  }

  group('a single move loses the round for the mover', () {
    test('the other player is credited with the win once the jitter window elapses', () {
      final e = frozenEngine();
      e.onMotionSample(playerA, 0.5, t0);
      expect(e.state, isA<ResolvingFreezeState>());

      e.checkMoveWindowElapsed(t0.add(const Duration(milliseconds: 151)));

      final result = e.state as FreezeResultState;
      expect(result.outcome.winnerId, playerB);
      expect(result.outcome.reason, FreezeEndReason.moved);
    });

    test('a motion sample below the threshold is ignored entirely', () {
      final e = frozenEngine();
      e.onMotionSample(playerA, 0.01, t0);

      expect(e.state, isA<FrozenState>());
    });
  });

  group('simultaneous move draw (boundary, same convention as crack-window jitter)', () {
    test('149ms apart draws', () {
      final e = frozenEngine();
      e.onMotionSample(playerA, 0.5, t0);
      e.onMotionSample(playerB, 0.5, t0.add(const Duration(milliseconds: 149)));

      final result = e.state as FreezeResultState;
      expect(result.outcome.isDraw, isTrue);
      expect(result.outcome.reason, FreezeEndReason.simultaneousMove);
    });

    test('151ms apart does NOT draw — the first mover loses once the window elapses', () {
      final e = frozenEngine();
      e.onMotionSample(playerA, 0.5, t0);
      e.onMotionSample(playerB, 0.5, t0.add(const Duration(milliseconds: 151)));
      // Second move outside the jitter window doesn't finalize by itself.
      expect(e.state, isA<ResolvingFreezeState>());

      e.checkMoveWindowElapsed(t0.add(const Duration(milliseconds: 151)));

      final result = e.state as FreezeResultState;
      expect(result.outcome.winnerId, playerB);
      expect(result.outcome.reason, FreezeEndReason.moved);
    });
  });

  group('round timeout', () {
    test('nobody moving before the window elapses draws the round', () {
      final e = frozenEngine();
      e.checkWindowElapsed(windowEndsAt.add(const Duration(milliseconds: 1)));

      final result = e.state as FreezeResultState;
      expect(result.outcome.isDraw, isTrue);
      expect(result.outcome.reason, FreezeEndReason.timeout);
    });
  });

  group('reset', () {
    test('unconditionally returns to Building even from a resolved round, so a second callFreeze actually arms', () {
      final e = frozenEngine();
      e.checkWindowElapsed(windowEndsAt.add(const Duration(milliseconds: 1)));
      expect(e.state, isA<FreezeResultState>());

      e.reset();
      expect(e.state, isA<BuildingFreezeState>());

      // callFreeze is guarded to only fire from BuildingFreezeState —
      // without a real reset() this second call would silently no-op,
      // exactly the bug this test guards against.
      e.callFreeze(windowEndsAt.add(const Duration(seconds: 3)));
      expect(e.state, isA<FrozenState>());
    });
  });
}
