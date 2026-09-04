import 'package:flutter/foundation.dart';

/// Which Flutter build mode is currently running, expressed as our own enum
/// rather than three loose `kDebugMode`/`kProfileMode`/`kReleaseMode` bools
/// scattered across call sites.
enum AppBuildMode { debug, profile, release }

AppBuildMode get currentBuildMode {
  if (kReleaseMode) return AppBuildMode.release;
  if (kProfileMode) return AppBuildMode.profile;
  return AppBuildMode.debug;
}

/// Single edit point for which build mode(s) device-tier-based visual
/// downgrades (`ShimmerCard`'s sweep skip, `FloatingNavBar`'s blur skip, ...)
/// actually apply in. Defaults to release only — the dev wants every
/// animation at full quality while building/testing regardless of what tier
/// this machine or simulator happens to resolve to, and Flutter's own
/// `FrameTiming`/`SchedulerBinding.addTimingsCallback` docs note debug-mode
/// timings aren't representative of real device performance either, so
/// treating debug as "always full quality" is consistent with that, not just
/// a convenience. Add `AppBuildMode.profile` here too if you want to preview
/// the low-tier fallback UI locally via a profile build.
const gatedBuildModes = {AppBuildMode.release};

bool get isPerformanceGatingActive => gatedBuildModes.contains(currentBuildMode);
