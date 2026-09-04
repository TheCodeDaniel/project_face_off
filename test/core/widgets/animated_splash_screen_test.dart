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

  testWidgets('fills the full screen even inside an AnimatedSwitcher with a custom layoutBuilder', (tester) async {
    // Regression test: AnimatedSwitcher's *default* layoutBuilder wraps its
    // child as a non-Positioned Stack child, which gets loose constraints —
    // the splash (and anything else swapped through AppRoot's switcher)
    // would shrink-wrap to its content's width instead of filling the
    // device. AppRoot's layoutBuilder wraps each child in Positioned.fill to
    // fix that; this reproduces that exact wrapping to prove it holds.
    const screenSize = Size(390, 844);
    tester.view.physicalSize = screenSize;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          layoutBuilder: (currentChild, previousChildren) {
            return Stack(
              alignment: Alignment.center,
              children: [
                for (final previous in previousChildren) Positioned.fill(child: previous),
                if (currentChild != null) Positioned.fill(child: currentChild),
              ],
            );
          },
          child: const AnimatedSplashScreen(key: ValueKey('splash')),
        ),
      ),
    );
    await tester.pump();

    expect(tester.getSize(find.byType(AnimatedSplashScreen)), screenSize);
  });
}
