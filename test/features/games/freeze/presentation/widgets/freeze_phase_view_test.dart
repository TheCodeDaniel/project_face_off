import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_face_off/core/theme/match_palette.dart';
import 'package:project_face_off/core/widgets/floating_label_layer.dart';
import 'package:project_face_off/features/games/freeze/domain/freeze_outcome.dart';
import 'package:project_face_off/features/games/freeze/domain/freeze_state.dart';
import 'package:project_face_off/features/games/freeze/presentation/widgets/freeze_phase_view.dart';

/// Smoke test for the visual layer (game/UI/backend guideline Section 1).
/// Fixed-duration `pump()`s only — `LayeredDepthScene` runs a continuous,
/// indefinitely-repeating sway animation, so `pumpAndSettle()` would time
/// out here, same documented gotcha as `BowDrawPhaseView`'s test.
void main() {
  Widget wrap(FreezeState state) {
    return MaterialApp(
      theme: ThemeData(extensions: const [MatchPalette.standard]),
      home: Scaffold(
        body: FreezePhaseView(state: state, labelController: FloatingLabelController()),
      ),
    );
  }

  testWidgets('renders the building phase without throwing', (tester) async {
    await tester.pumpWidget(wrap(const BuildingFreezeState()));
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);
    expect(find.text('Keep moving…'), findsOneWidget);
  });

  testWidgets('renders the frozen phase without throwing', (tester) async {
    await tester.pumpWidget(wrap(FrozenState(windowEndsAt: DateTime(2026))));
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);
    expect(find.text('FREEZE!'), findsOneWidget);
  });

  testWidgets('renders the result phase (no phase message) without throwing', (tester) async {
    await tester.pumpWidget(
      wrap(
        const FreezeResultState(
          outcome: FreezeOutcome(winnerId: 'me', reason: FreezeEndReason.moved),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);
  });
}
