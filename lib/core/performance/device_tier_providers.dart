import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'device_tier.dart';
import 'device_tier_repository.dart';
import 'device_tier_service.dart';

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
