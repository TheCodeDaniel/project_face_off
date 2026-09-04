import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_face_off/core/performance/device_tier.dart';
import 'package:project_face_off/core/performance/device_tier_providers.dart';
import 'package:project_face_off/core/theme/app_theme.dart';
import 'package:project_face_off/core/widgets/shimmer_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpCard(WidgetTester tester, DeviceTier tier) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [effectiveDeviceTierProvider.overrideWith((ref) => AsyncValue.data(tier))],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(body: ShimmerCard(child: Text('content'))),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('renders correctly regardless of device tier', (tester) async {
    await pumpCard(tester, DeviceTier.low);
    expect(find.text('content'), findsOneWidget);

    await pumpCard(tester, DeviceTier.high);
    expect(find.text('content'), findsOneWidget);
  });

  testWidgets('on a low-tier device, the sweep never starts even well past its max initial delay', (tester) async {
    await pumpCard(tester, DeviceTier.low);

    // The sweep's own first-run delay is randomized up to 300+3500=3800ms
    // (see ShimmerCard._maybeStartScheduling) — stepping well past that
    // with no animation ever starting is the actual proof the sweep was
    // skipped, not just that dispose() cleans up (which it does either way,
    // so asserting "no pending timer after disposal" alone doesn't
    // distinguish gated-on-low-tier from never-gated-at-all).
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(seconds: 1));
      expect(tester.hasRunningAnimations, isFalse);
    }
  });

  testWidgets('on a higher tier, the sweep does eventually start', (tester) async {
    await pumpCard(tester, DeviceTier.high);

    var animated = false;
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(seconds: 1));
      if (tester.hasRunningAnimations) animated = true;
    }
    expect(animated, isTrue);
  });
}
