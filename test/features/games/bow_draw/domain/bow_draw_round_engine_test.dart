import 'package:flutter_test/flutter_test.dart';
import 'package:project_face_off/features/games/bow_draw/domain/bow_draw_round_engine.dart';
import 'package:project_face_off/features/games/bow_draw/domain/draw_outcome.dart';
import 'package:project_face_off/features/games/bow_draw/domain/draw_state.dart';

void main() {
  const playerA = 'playerA';
  const playerB = 'playerB';
  final t0 = DateTime.utc(2026, 1, 1);
  final windowEndsAt = t0.add(const Duration(seconds: 6));

  BowDrawRoundEngine armedEngine({double targetPower = 0.6}) {
    final e = BowDrawRoundEngine(playerAId: playerA, playerBId: playerB);
    e.armRound(targetPower, windowEndsAt);
    return e;
  }

  group('a clean hit wins outright', () {
    test('a shot within tolerance of the target power wins immediately', () {
      final e = armedEngine(targetPower: 0.6);
      e.onShoot(playerA, 0.5); // within 0.15 tolerance of 0.6

      final result = e.state as DrawResultState;
      expect(result.outcome.winnerId, playerA);
      expect(result.outcome.reason, DrawEndReason.hit);
    });

    test('a shot outside tolerance misses without ending the round', () {
      final e = armedEngine(targetPower: 0.6);
      e.onShoot(playerA, 0.1); // 0.5 away, well outside tolerance

      final s = e.state as ArmedDrawState;
      expect(s.missed, {playerA});
    });
  });

  group('both missed', () {
    test('both players missing draws the round', () {
      final e = armedEngine(targetPower: 0.6);
      e.onShoot(playerA, 0.1);
      e.onShoot(playerB, 0.9);

      final result = e.state as DrawResultState;
      expect(result.outcome.isDraw, isTrue);
      expect(result.outcome.reason, DrawEndReason.bothMissed);
    });

    test("the second player can still land a hit after the first player's miss", () {
      final e = armedEngine(targetPower: 0.6);
      e.onShoot(playerA, 0.1); // miss
      e.onShoot(playerB, 0.55); // hit

      final result = e.state as DrawResultState;
      expect(result.outcome.winnerId, playerB);
      expect(result.outcome.reason, DrawEndReason.hit);
    });
  });

  group('round window timeout', () {
    test('neither player shooting before the window elapses draws the round', () {
      final e = armedEngine();
      e.checkWindowElapsed(windowEndsAt.add(const Duration(milliseconds: 1)));

      final result = e.state as DrawResultState;
      expect(result.outcome.isDraw, isTrue);
      expect(result.outcome.reason, DrawEndReason.timeout);
    });

    test('does nothing if the window has not actually elapsed yet', () {
      final e = armedEngine();
      e.checkWindowElapsed(windowEndsAt.subtract(const Duration(seconds: 1)));

      expect(e.state, isA<ArmedDrawState>());
    });
  });

  group('reset', () {
    test('unconditionally returns to Neutral even from a resolved round, so a second armRound actually arms', () {
      final e = armedEngine();
      e.checkWindowElapsed(windowEndsAt.add(const Duration(milliseconds: 1)));
      expect(e.state, isA<DrawResultState>());

      e.reset();
      expect(e.state, isA<NeutralDrawState>());

      // armRound is guarded to only fire from NeutralDrawState — without a
      // real reset() this second call would silently no-op, which is
      // exactly the bug this test guards against.
      e.armRound(0.6, windowEndsAt.add(const Duration(seconds: 6)));
      expect(e.state, isA<ArmedDrawState>());
    });
  });
}
