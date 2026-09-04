import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';

import 'device_tier.dart';

/// Resolves this device's [DeviceTier]. Kept as its own interface (rather
/// than a bare top-level function) so tests can substitute a fixed tier
/// instead of depending on real platform-channel device info.
abstract class DeviceTierService {
  Future<DeviceTier> resolveTier();
}

/// Buckets by physical RAM via `device_info_plus`, not CPU core count.
///
/// Core count alone is a bad proxy for real-world performance: a Samsung
/// A53 (8 cores, 2.0GHz with 2 cores at 2.4GHz) has *more* cores than an
/// iPhone 12 (6 cores, 4 at 3.1GHz + 2 at 1.8GHz) but is meaningfully
/// slower in practice — per-core clock speed and microarchitecture matter
/// more than the raw count, and a naive core-count bucket would have
/// classified the A53 as the more capable device. RAM is a better single
/// signal (it's what actually constrains how many `ShimmerCard`/blur
/// surfaces can be alive at once without the OS reclaiming memory), and on
/// Android, [AndroidDeviceInfo.isLowRamDevice] is an outright authoritative
/// override — it's a direct passthrough of the OS's own
/// `ActivityManager.isLowRamDevice()`, i.e. Android itself has already
/// decided this device is memory-constrained.
///
/// iOS gets *lower* RAM thresholds than Android for the same tier: Apple's
/// tighter hardware/OS integration means a given RAM figure performs like
/// meaningfully more RAM does on Android (the same iPhone-12-vs-A53
/// comparison above — a 4GB iPhone 12 outperforms a 6-8GB A53 despite less
/// RAM and fewer cores). This is still a coarse proxy, not a real GPU
/// benchmark; `dart:ui`'s `FrameTiming` (via
/// `SchedulerBinding.addTimingsCallback`) measuring actual build/raster
/// durations at runtime would be the natural v2 upgrade if this ever needs
/// to be more precise — deferred for now since it's only reliable in
/// profile/release builds and adds ongoing-measurement complexity a
/// one-shot-at-launch signal doesn't need.
class PlatformDeviceTierService implements DeviceTierService {
  PlatformDeviceTierService({DeviceInfoPlugin? deviceInfoPlugin})
    : _deviceInfoPlugin = deviceInfoPlugin ?? DeviceInfoPlugin();

  final DeviceInfoPlugin _deviceInfoPlugin;

  @override
  Future<DeviceTier> resolveTier() async {
    if (Platform.isAndroid) {
      final info = await _deviceInfoPlugin.androidInfo;
      if (info.isLowRamDevice) return DeviceTier.low;
      return classifyByRamMb(info.physicalRamSize, isIOS: false);
    }
    if (Platform.isIOS) {
      final info = await _deviceInfoPlugin.iosInfo;
      return classifyByRamMb(info.physicalRamSize, isIOS: true);
    }
    // Desktop/web dev builds: no meaningful "low-power device" concept,
    // default to the safe middle rather than assuming either extreme.
    return DeviceTier.mid;
  }
}

/// Pure classification, split out from [PlatformDeviceTierService] so the
/// threshold logic is testable without depending on real platform channels.
/// `ramMb` is physical RAM in megabytes, as reported by `device_info_plus`.
DeviceTier classifyByRamMb(int ramMb, {required bool isIOS}) {
  final lowCeilingMb = isIOS ? 2048 : 3072;
  final midCeilingMb = isIOS ? 4096 : 6144;
  if (ramMb <= lowCeilingMb) return DeviceTier.low;
  if (ramMb <= midCeilingMb) return DeviceTier.mid;
  return DeviceTier.high;
}
