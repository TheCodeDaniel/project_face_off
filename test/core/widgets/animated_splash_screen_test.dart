import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_face_off/core/theme/app_theme.dart';
import 'package:project_face_off/core/widgets/animated_splash_screen.dart';

void main() {
  testWidgets('plays through the logo/wordmark/shine sequence without throwing', (tester) async {
    await tester.pumpWidget(MaterialApp(theme: AppTheme.light, home: const AnimatedSplashScreen()));

    // Step through the whole 2.4s timeline in chunks rather than
    // pumpAndSettle, so a math error partway through the animation (e.g. a
    // phase's progress going out of the 0..1 range a widget expects) would
    // surface as a thrown exception here.
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 450));
    }

    expect(tester.takeException(), isNull);
    expect(find.text('FACE OFF'), findsOneWidget);
  });
}
