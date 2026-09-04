import 'dart:io';

import 'device_tier.dart';

/// Resolves this device's [DeviceTier]. Kept as its own interface (rather
/// than a bare top-level function) so tests can substitute a fixed tier
/// instead of depending on the real host's core count.
abstract class DeviceTierService {
  DeviceTier resolveTier();
}

/// Buckets by logical CPU core count — a genuinely "lightweight" signal
/// (Blueprint Section 6), available with no new plugin dependency, that
/// correlates reasonably well with a device's overall class. This is a
/// coarse proxy, not a real GPU/RAM benchmark; if it ever needs to be more
/// precise, `device_info_plus` (screen density, RAM) would be the natural
/// upgrade — nothing else in this file's callers would need to change,
/// since they only ever see the resolved [DeviceTier].
class PlatformDeviceTierService implements DeviceTierService {
  @override
  DeviceTier resolveTier() => classifyByCoreCount(Platform.numberOfProcessors);
}

/// Pure classification, split out from [PlatformDeviceTierService] so the
/// threshold logic is testable without depending on the real host's core
/// count.
DeviceTier classifyByCoreCount(int cores) {
  if (cores <= 4) return DeviceTier.low;
  if (cores <= 7) return DeviceTier.mid;
  return DeviceTier.high;
}
