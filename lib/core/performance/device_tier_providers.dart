import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'device_tier.dart';
import 'device_tier_repository.dart';
import 'device_tier_service.dart';
import 'performance_gating_config.dart';

final deviceTierServiceProvider = Provider<DeviceTierService>((ref) => PlatformDeviceTierService());

final deviceTierRepositoryProvider = Provider<DeviceTierRepository>((ref) {
  return DeviceTierRepository(ref.watch(deviceTierServiceProvider));
});

/// Resolves once per app session (cached across launches by the repository
/// — see its doc comment). Consumers default to [DeviceTier.high] while
/// this is still loading (`valueOrNull ?? DeviceTier.high`) so there's no
/// flash of reduced-quality UI before the (near-instant, after the first
/// launch) cache read resolves.
final deviceTierProvider = FutureProvider<DeviceTier>((ref) => ref.watch(deviceTierRepositoryProvider).resolveTier());

/// What `ShimmerCard`/`FloatingNavBar`/etc. should actually watch instead of
/// [deviceTierProvider] directly. Outside the build modes configured in
/// [gatedBuildModes] (debug, by default), this always reports
/// [DeviceTier.high] — full-quality animations — regardless of the real
/// resolved tier, so a low-RAM dev machine or simulator never hides the
/// effects you're trying to see while building. See
/// `performance_gating_config.dart` for the single toggle point.
final effectiveDeviceTierProvider = Provider<AsyncValue<DeviceTier>>((ref) {
  if (!isPerformanceGatingActive) return const AsyncValue.data(DeviceTier.high);
  return ref.watch(deviceTierProvider);
});
