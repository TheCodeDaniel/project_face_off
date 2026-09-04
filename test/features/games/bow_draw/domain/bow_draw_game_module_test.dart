import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_face_off/core/game_engine/landmarker_type.dart';
import 'package:project_face_off/core/game_engine/match_round_outcome.dart';
import 'package:project_face_off/features/games/bow_draw/domain/bow_draw_game_module.dart';

void main() {
  group('BowDrawGameModule (GameModule contract compliance)', () {
    test('startRound arms the round; the window timer resolves it as a timeout draw if nobody shoots', () {
      fakeAsync((async) {
        final module = BowDrawGameModule(playerAId: 'me', playerBId: 'opponent');
        addTearDown(module.dispose);

        MatchRoundOutcome? outcome;
        module.roundOutcomes.listen((o) => outcome = o);

        module.startRound();
        async.elapse(const Duration(seconds: 7)); // past the 6s shot window

        expect(outcome, isNotNull);
        expect(outcome!.isDraw, isTrue);
        expect(outcome!.reasonCode, 'timeout');
      });
    });

    test('resetRound cancels the window timer — no outcome fires after', () {
      fakeAsync((async) {
        final module = BowDrawGameModule(playerAId: 'me', playerBId: 'opponent');
        addTearDown(module.dispose);

        var outcomeCount = 0;
        module.roundOutcomes.listen((_) => outcomeCount++);

        module.startRound();
        module.resetRound();
        async.elapse(const Duration(seconds: 7));

        expect(outcomeCount, 0);
      });
    });

    test('requiredLandmarkers declares hand only', () {
      final module = BowDrawGameModule(playerAId: 'me', playerBId: 'opponent');
      addTearDown(module.dispose);
      expect(module.requiredLandmarkers, {LandmarkerType.hand});
    });
  });
}
