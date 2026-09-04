import 'package:flutter_test/flutter_test.dart';
import 'package:project_face_off/features/duel/domain/duel_round_engine.dart';
import 'package:project_face_off/features/duel/domain/round_outcome.dart';
import 'package:project_face_off/features/duel/domain/round_state.dart';

void main() {
  const playerA = 'playerA';
  const playerB = 'playerB';
  final t0 = DateTime.utc(2026, 1, 1);

  DuelRoundEngine engine() => DuelRoundEngine(playerAId: playerA, playerBId: playerB);

  void reachCueFired(DuelRoundEngine e, {DateTime? fireAt}) {
    e.playerReachedNeutral(playerA);
    e.playerReachedNeutral(playerB);
    e.armCue(t0.add(const Duration(seconds: 2)));
    e.fireCue(fireAt ?? t0.add(const Duration(seconds: 2)));
  }

  group('normal fire/dodge resolution', () {
    test('attacker wins when no dodge arrives before window elapses', () {
      final e = engine();
      reachCueFired(e);
      final fireAt = t0.add(const Duration(seconds: 2));
      e.onFireGesture(playerA, fireAt);
      e.checkDodgeWindowElapsed(fireAt.add(const Duration(milliseconds: 401)));

      final result = e.state as RoundResultRoundState;
      expect(result.outcome.winnerId, playerA);
      expect(result.outcome.reason, RoundEndReason.firedFirst);
      expect(e.scores[playerA], 1);
    });
  });

  group('successful dodge', () {
    test('resets to an open exchange instead of instantly winning (spec default)', () {
      final e = engine();
      reachCueFired(e);
      final fireAt = t0.add(const Duration(seconds: 2));
      e.onFireGesture(playerA, fireAt);
      e.onDodgeGesture(playerB, fireAt.add(const Duration(milliseconds: 200)));

      final s = e.state as CueFiredRoundState;
      expect(s.attackerId, isNull);
      expect(e.scores[playerA], 0);
      expect(e.scores[playerB], 0);
    });
  });

  group('false start', () {
    test('player A firing before authoritative cue-fire time instantly loses', () {
      final e = engine();
      e.playerReachedNeutral(playerA);
      e.playerReachedNeutral(playerB);
      final cueFireAt = t0.add(const Duration(seconds: 2));
      e.armCue(cueFireAt);
      e.onFireGesture(playerA, cueFireAt.subtract(const Duration(milliseconds: 10)));

      final result = e.state as RoundResultRoundState;
      expect(result.outcome.winnerId, playerB);
      expect(result.outcome.reason, RoundEndReason.falseStart);
    });

    test('player B firing before authoritative cue-fire time instantly loses', () {
      final e = engine();
      e.playerReachedNeutral(playerA);
      e.playerReachedNeutral(playerB);
      final cueFireAt = t0.add(const Duration(seconds: 2));
      e.armCue(cueFireAt);
      e.onFireGesture(playerB, cueFireAt.subtract(const Duration(milliseconds: 10)));

      final result = e.state as RoundResultRoundState;
      expect(result.outcome.winnerId, playerA);
      expect(result.outcome.reason, RoundEndReason.falseStart);
    });
  });

  group('crack detection at every phase', () {
    test('crack during Neutral', () {
      final e = engine();
      e.playerReachedNeutral(playerA);
      e.onCrackGesture(playerA, t0);
      e.checkCrackWindowElapsed(t0.add(const Duration(milliseconds: 151)));

      final result = e.state as RoundResultRoundState;
      expect(result.outcome.winnerId, playerB);
      expect(result.outcome.reason, RoundEndReason.cracked);
    });

    test('crack during CueArmed', () {
      final e = engine();
      e.playerReachedNeutral(playerA);
      e.playerReachedNeutral(playerB);
      e.armCue(t0.add(const Duration(seconds: 2)));
      e.onCrackGesture(playerB, t0.add(const Duration(milliseconds: 500)));
      e.checkCrackWindowElapsed(t0.add(const Duration(milliseconds: 700)));

      final result = e.state as RoundResultRoundState;
      expect(result.outcome.winnerId, playerA);
      expect(result.outcome.reason, RoundEndReason.cracked);
    });

    test('crack during CueFired overrides an in-progress exchange', () {
      final e = engine();
      reachCueFired(e);
      final fireAt = t0.add(const Duration(seconds: 2));
      e.onFireGesture(playerA, fireAt);
      e.onCrackGesture(playerA, fireAt.add(const Duration(milliseconds: 50)));
      e.checkCrackWindowElapsed(fireAt.add(const Duration(milliseconds: 250)));

      final result = e.state as RoundResultRoundState;
      expect(result.outcome.winnerId, playerB);
      expect(result.outcome.reason, RoundEndReason.cracked);
    });
  });

  group('simultaneous crack draw', () {
    test('both players crack within 150ms -> draw, no score change', () {
      final e = engine();
      reachCueFired(e);
      final fireAt = t0.add(const Duration(seconds: 2));
      e.onCrackGesture(playerA, fireAt);
      e.onCrackGesture(playerB, fireAt.add(const Duration(milliseconds: 100)));

      final result = e.state as RoundResultRoundState;
      expect(result.outcome.isDraw, isTrue);
      expect(result.outcome.reason, RoundEndReason.simultaneousCrack);
      expect(e.scores[playerA], 0);
      expect(e.scores[playerB], 0);
    });

    test('cracks more than 150ms apart do not count as simultaneous', () {
      final e = engine();
      reachCueFired(e);
      final fireAt = t0.add(const Duration(seconds: 2));
      e.onCrackGesture(playerA, fireAt);
      e.onCrackGesture(playerB, fireAt.add(const Duration(milliseconds: 300)));

      // Second crack outside the window doesn't finalize by itself.
      expect(e.state, isA<ResolvingRoundState>());
      e.checkCrackWindowElapsed(fireAt.add(const Duration(milliseconds: 200)));

      final result = e.state as RoundResultRoundState;
      expect(result.outcome.winnerId, playerB);
      expect(result.outcome.reason, RoundEndReason.cracked);
    });
  });

  group('round timeout draw', () {
    test('neither player fires within the round timeout -> draw', () {
      final e = engine();
      reachCueFired(e);
      final cueFiredAt = t0.add(const Duration(seconds: 2));
      e.checkRoundTimeout(cueFiredAt.add(const Duration(seconds: 9)));

      final result = e.state as RoundResultRoundState;
      expect(result.outcome.isDraw, isTrue);
      expect(result.outcome.reason, RoundEndReason.timeout);
    });
  });

  group('full best-of-5 match completion', () {
    test('first to 3 round wins takes the match', () {
      final e = engine();
      for (var i = 0; i < 3; i++) {
        e.startNeutralPhase();
        reachCueFired(e);
        final fireAt = t0.add(const Duration(seconds: 2));
        e.onFireGesture(playerA, fireAt);
        e.checkDodgeWindowElapsed(fireAt.add(const Duration(milliseconds: 401)));
        expect(e.state, isA<RoundResultRoundState>());

        if (i < 2) {
          e.advanceAfterRecap();
          expect(e.state, isA<NeutralRoundState>());
        }
      }

      e.advanceAfterRecap();
      final matchResult = e.state as MatchResultRoundState;
      expect(matchResult.winnerId, playerA);
      expect(matchResult.scores[playerA], 3);
    });
  });

  group('round number tracking', () {
    test('starts at 1 and increments on advance to a new round', () {
      final e = engine();
      expect(e.roundNumber, 1);

      reachCueFired(e);
      final fireAt = t0.add(const Duration(seconds: 2));
      e.onFireGesture(playerA, fireAt);
      e.checkDodgeWindowElapsed(fireAt.add(const Duration(milliseconds: 401)));
      e.advanceAfterRecap();

      expect(e.roundNumber, 2);
    });

    test('a draw still consumes a round (unlike scores, which stay unchanged)', () {
      final e = engine();
      reachCueFired(e);
      e.checkRoundTimeout(t0.add(const Duration(seconds: 11)));
      expect((e.state as RoundResultRoundState).outcome.isDraw, isTrue);

      e.advanceAfterRecap();

      expect(e.roundNumber, 2);
      expect(e.scores[playerA], 0);
      expect(e.scores[playerB], 0);
    });

    test('does not increment past the round that ends the match', () {
      final e = engine();
      for (var i = 0; i < 3; i++) {
        e.startNeutralPhase();
        reachCueFired(e);
        final fireAt = t0.add(const Duration(seconds: 2));
        e.onFireGesture(playerA, fireAt);
        e.checkDodgeWindowElapsed(fireAt.add(const Duration(milliseconds: 401)));
        e.advanceAfterRecap();
      }

      expect(e.state, isA<MatchResultRoundState>());
      expect(e.roundNumber, 3);
    });
  });

  group('forfeit (master prompt Section 12 — connectivity-loss grace period)', () {
    test('credits the other player with the win regardless of the current score', () {
      final e = engine();
      reachCueFired(e);
      final fireAt = t0.add(const Duration(seconds: 2));
      e.onFireGesture(playerA, fireAt);
      e.checkDodgeWindowElapsed(fireAt.add(const Duration(milliseconds: 401)));
      expect(e.scores[playerA], 1);

      e.forfeit(playerA);

      final result = e.state as MatchResultRoundState;
      expect(result.winnerId, playerB);
    });

    test('ends the match from mid-round, not just between rounds', () {
      final e = engine();
      reachCueFired(e);

      e.forfeit(playerB);

      expect(e.state, isA<MatchResultRoundState>());
      expect((e.state as MatchResultRoundState).winnerId, playerA);
    });
  });
}
