import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_face_off/core/theme/match_palette.dart';
import 'package:project_face_off/core/widgets/floating_label_layer.dart';
import 'package:project_face_off/features/games/bow_draw/domain/draw_outcome.dart';
import 'package:project_face_off/features/games/bow_draw/domain/draw_state.dart';
import 'package:project_face_off/features/games/bow_draw/presentation/widgets/bow_draw_phase_view.dart';

/// Smoke test for the visual layer (game/UI/backend guideline Section 1).
/// Uses fixed-duration `pump()`s, never `pumpAndSettle()` — `LayeredDepthScene`
/// and `BowDrawTarget` both run continuous, indefinitely-repeating
/// animations (same documented gotcha as the product-tour and `ShimmerCard`
/// tests), so `pumpAndSettle()` would time out here too.
void main() {
  Widget wrap(DrawState state, {double livePower = 0}) {
    return MaterialApp(
      theme: ThemeData(extensions: const [MatchPalette.standard]),
      home: Scaffold(
        body: BowDrawPhaseView(state: state, livePower: livePower, labelController: FloatingLabelController()),
      ),
    );
  }

  testWidgets('renders the neutral phase without throwing or overflowing', (tester) async {
    await tester.pumpWidget(wrap(const NeutralDrawState()));
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);
    expect(find.text('Get ready…'), findsOneWidget);
  });

  testWidgets('renders the armed phase with a mid-draw bow rig without throwing', (tester) async {
    await tester.pumpWidget(wrap(ArmedDrawState(targetPower: 0.6, windowEndsAt: DateTime(2026)), livePower: 0.5));
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);
    expect(find.text('Take your shot!'), findsOneWidget);
  });

  testWidgets('renders the result phase (no phase message) without throwing', (tester) async {
    await tester.pumpWidget(
      wrap(
        const DrawResultState(
          outcome: DrawOutcome(winnerId: 'me', reason: DrawEndReason.hit),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);
  });
}
