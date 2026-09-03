import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_face_off/core/theme/app_theme.dart';
import 'package:project_face_off/core/widgets/animated_splash_screen.dart';

void main() {
  testWidgets('plays through the full glove-clash choreography without throwing, ending on the title', (tester) async {
    await tester.pumpWidget(MaterialApp(theme: AppTheme.light, home: const AnimatedSplashScreen()));

    // Step through the whole 3.2s timeline in chunks rather than
    // pumpAndSettle — the AnimationController runs once and settles on its
    // own, but stepping catches any exception thrown mid-animation (e.g.
    // from a phase's math going out of the 0..1 range a widget expects).
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 450));
    }

    expect(tester.takeException(), isNull);
    expect(find.text('Face Off'), findsOneWidget);
    expect(find.text("Face your friends. Don't flinch."), findsOneWidget);
  });
}
