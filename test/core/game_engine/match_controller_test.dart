import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_face_off/core/game_engine/game_pool.dart';
import 'package:project_face_off/core/game_engine/match_controller.dart';
import 'package:project_face_off/core/game_engine/match_state.dart';
import 'package:project_face_off/features/games/face_off/domain/face_off_game_module.dart';

void main() {
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

        controller.startMatch(GameId.faceOff, 'Bot');

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

        controller.startMatch(GameId.faceOff, 'Bot');
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

        controller.startMatch(GameId.faceOff, 'Bot');

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

          controller.startMatch(GameId.faceOff, 'Bot');

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

          controller.startMatch(GameId.faceOff, 'Bot');
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

          controller.startMatch(GameId.faceOff, 'Bot');
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

          controller.startMatch(GameId.faceOff, 'Bot');
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
