import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_face_off/core/performance/device_tier.dart';
import 'package:project_face_off/core/performance/device_tier_providers.dart';

void main() {
  test('effectiveDeviceTierProvider reports high when the real tier is low, since gating is off in test/debug', () {
    final container = ProviderContainer(overrides: [deviceTierProvider.overrideWith((ref) async => DeviceTier.low)]);
    addTearDown(container.dispose);

    // Tests run under kDebugMode (kReleaseMode is false), and gatedBuildModes
    // defaults to release-only — so effectiveDeviceTierProvider must ignore
    // the real (low) resolved tier and always report high here.
    final effective = container.read(effectiveDeviceTierProvider);

    expect(effective, const AsyncValue<DeviceTier>.data(DeviceTier.high));
  });
}
