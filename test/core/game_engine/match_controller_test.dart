import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_face_off/core/game_engine/game_pool.dart';
import 'package:project_face_off/core/game_engine/match_controller.dart';
import 'package:project_face_off/core/game_engine/match_state.dart';
import 'package:project_face_off/features/games/bow_draw/domain/bow_draw_game_module.dart';
import 'package:project_face_off/features/games/face_off/domain/face_off_game_module.dart';
import 'package:project_face_off/features/games/freeze/domain/freeze_game_module.dart';
import 'package:project_face_off/features/games/freeze/domain/freeze_state.dart';

void main() {
  test('MatchController correctly re-arms Bow & Draw across multiple rounds, not just the first', () {
    fakeAsync((async) {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.listen(matchControllerProvider, (_, _) {});
      final controller = container.read(matchControllerProvider.notifier);

      controller.startMatch(
        gameId: GameId.bowDraw,
        matchId: 'match-1',
        realOpponentId: 'opponent-uid',
        opponentLabel: 'Bot',
      );

      for (var i = 0; i < 2; i++) {
        final module = controller.activeModule as BowDrawGameModule;
        // Target power is randomized 0.3-0.9 with a ±0.15 hit tolerance —
        // three shots spaced 0.3 apart cover the whole range (worst case,
        // exactly between two shots, lands exactly at the tolerance
        // boundary). Once a shot lands the round resolves immediately and
        // the module ignores the remaining calls (state is no longer armed).
        module.triggerShoot(MatchController.meId, 0.3);
        module.triggerShoot(MatchController.meId, 0.6);
        module.triggerShoot(MatchController.meId, 0.9);
        async.elapse(const Duration(seconds: 3)); // recap -> next round
      }

      // Two rounds resolved (each as a win for meId, since only meId ever
      // shoots) without yet reaching the 3-win match threshold — without
      // BowDrawRoundEngine.reset() being called between rounds, the second
      // round's armRound() would silently no-op and this round counter
      // would still read 2, stuck showing PlayingRoundMatchState with a
      // round that was never actually armed.
      expect(controller.roundNumber, 3);
      expect(controller.scores[MatchController.meId], 2);
      expect(container.read(matchControllerProvider), isA<PlayingRoundMatchState>());
    });
  });

  test(
    'MatchController is truly game-agnostic — best-of-5 scoring works identically with a different game plugged in',
    () {
      fakeAsync((async) {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        container.listen(matchControllerProvider, (_, _) {});
        final controller = container.read(matchControllerProvider.notifier);

        controller.startMatch(
          gameId: GameId.freeze,
          matchId: 'match-1',
          realOpponentId: 'opponent-uid',
          opponentLabel: 'Bot',
        );
        expect(controller.activeModule, isA<FreezeGameModule>());

        for (var i = 0; i < 3; i++) {
          final module = controller.activeModule as FreezeGameModule;
          // The build-up delay is randomized 1.5-4.5s and the freeze window
          // is only 3s long — a single fixed elapse long enough to always
          // clear the build-up (e.g. 5s) can therefore overshoot straight
          // through the window's own shorter timeout for a small build-up
          // draw, timing the round out as a draw before triggerMove ever
          // runs. Stepping in small increments and stopping the instant
          // Frozen is reached avoids that regardless of the random draw.
          while (module.freezeState is! FrozenState) {
            async.elapse(const Duration(milliseconds: 100));
          }
          module.triggerMove(MatchController.opponentId); // opponent moves, I win the round
          async.elapse(const Duration(milliseconds: 200)); // past the simultaneous-move jitter window
          async.elapse(const Duration(seconds: 3)); // recap -> next round, or match complete on the 3rd
        }

        final result = container.read(matchControllerProvider) as MatchCompleteMatchState;
        expect(result.winnerId, MatchController.meId);
        expect(result.scores[MatchController.meId], 3);
      });
    },
  );

  group('MatchController (game-agnostic, driven here by the real Face Off module)', () {
    test('startMatch hands control to the picked game and starts a round', () {
      fakeAsync((async) {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        // matchControllerProvider is autoDispose (see its doc comment) so a
        // real screen's ref.watch tears its Timers down on exit; here we
        // need an explicit listener to keep it alive the same way that
        // watch does, or the provider disposes itself between reads.
        container.listen(matchControllerProvider, (_, _) {});
        final controller = container.read(matchControllerProvider.notifier);

        controller.startMatch(
          gameId: GameId.faceOff,
          matchId: 'match-1',
          realOpponentId: 'opponent-uid',
          opponentLabel: 'Bot',
        );

        expect(container.read(matchControllerProvider), isA<PlayingRoundMatchState>());
        expect(controller.activeModule, isA<FaceOffGameModule>());
        async.elapse(const Duration(seconds: 5)); // let the module's own cue timer settle
      });
    });

    test('a round outcome updates scores and enters recap, then advances to the next round', () {
      fakeAsync((async) {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        container.listen(matchControllerProvider, (_, _) {});
        final controller = container.read(matchControllerProvider.notifier);

        controller.startMatch(
          gameId: GameId.faceOff,
          matchId: 'match-1',
          realOpponentId: 'opponent-uid',
          opponentLabel: 'Bot',
        );
        async.elapse(const Duration(seconds: 5)); // past the max 4s cue delay -> CueFired

        final module = controller.activeModule as FaceOffGameModule;
        module.triggerFire(MatchController.meId);
        async.elapse(const Duration(milliseconds: 500)); // past the dodge window

        expect(container.read(matchControllerProvider), isA<RoundRecapMatchState>());
        expect(controller.scores[MatchController.meId], 1);
        expect(controller.roundNumber, 1);

        async.elapse(const Duration(seconds: 3)); // past the recap pause
        expect(container.read(matchControllerProvider), isA<PlayingRoundMatchState>());
        expect(controller.roundNumber, 2);
      });
    });

    test('first to 3 round wins ends the match, regardless of which game was playing', () {
      fakeAsync((async) {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        container.listen(matchControllerProvider, (_, _) {});
        final controller = container.read(matchControllerProvider.notifier);

        controller.startMatch(
          gameId: GameId.faceOff,
          matchId: 'match-1',
          realOpponentId: 'opponent-uid',
          opponentLabel: 'Bot',
        );

        for (var i = 0; i < 3; i++) {
          async.elapse(const Duration(seconds: 5));
          final module = controller.activeModule as FaceOffGameModule;
          module.triggerFire(MatchController.meId);
          async.elapse(const Duration(milliseconds: 500));
          async.elapse(const Duration(seconds: 3)); // recap -> next round, or match complete on the 3rd
        }

        final result = container.read(matchControllerProvider) as MatchCompleteMatchState;
        expect(result.winnerId, MatchController.meId);
        expect(result.scores[MatchController.meId], 3);
      });
    });

    group('connectivity handling (master prompt Section 12)', () {
      test('going offline pauses the match — the active module stops advancing it', () {
        fakeAsync((async) {
          final container = ProviderContainer();
          addTearDown(container.dispose);
          container.listen(matchControllerProvider, (_, _) {});
          final controller = container.read(matchControllerProvider.notifier);

          controller.startMatch(
            gameId: GameId.faceOff,
            matchId: 'match-1',
            realOpponentId: 'opponent-uid',
            opponentLabel: 'Bot',
          );

          controller.handleConnectivityChange(false);
          async.elapse(const Duration(seconds: 5)); // past the max cue delay if it were still running
          expect(container.read(matchControllerProvider), isA<PlayingRoundMatchState>());
        });
      });

      test('reconnecting before the forfeit timeout resumes with a fresh round', () {
        fakeAsync((async) {
          final container = ProviderContainer();
          addTearDown(container.dispose);
          container.listen(matchControllerProvider, (_, _) {});
          final controller = container.read(matchControllerProvider.notifier);

          controller.startMatch(
            gameId: GameId.faceOff,
            matchId: 'match-1',
            realOpponentId: 'opponent-uid',
            opponentLabel: 'Bot',
          );
          controller.handleConnectivityChange(false);
          async.elapse(const Duration(seconds: 10)); // well inside the 20s grace period

          controller.handleConnectivityChange(true);
          expect(container.read(matchControllerProvider), isA<PlayingRoundMatchState>());
          expect(controller.scores[MatchController.meId], 0);
          expect(controller.scores[MatchController.opponentId], 0);
        });
      });

      test('staying offline past the grace period forfeits the match to the opponent', () {
        fakeAsync((async) {
          final container = ProviderContainer();
          addTearDown(container.dispose);
          container.listen(matchControllerProvider, (_, _) {});
          final controller = container.read(matchControllerProvider.notifier);

          controller.startMatch(
            gameId: GameId.faceOff,
            matchId: 'match-1',
            realOpponentId: 'opponent-uid',
            opponentLabel: 'Bot',
          );
          controller.handleConnectivityChange(false);
          async.elapse(const Duration(seconds: 21)); // past the 20s grace period

          final result = container.read(matchControllerProvider) as MatchCompleteMatchState;
          expect(result.winnerId, MatchController.opponentId);
        });
      });

      test('going offline again after a forfeit is a no-op — the match already ended', () {
        fakeAsync((async) {
          final container = ProviderContainer();
          addTearDown(container.dispose);
          container.listen(matchControllerProvider, (_, _) {});
          final controller = container.read(matchControllerProvider.notifier);

          controller.startMatch(
            gameId: GameId.faceOff,
            matchId: 'match-1',
            realOpponentId: 'opponent-uid',
            opponentLabel: 'Bot',
          );
          controller.handleConnectivityChange(false);
          async.elapse(const Duration(seconds: 21));
          final forfeited = container.read(matchControllerProvider) as MatchCompleteMatchState;

          controller.handleConnectivityChange(true);
          controller.handleConnectivityChange(false);
          expect(container.read(matchControllerProvider), same(forfeited));
        });
      });
    });
  });
}
