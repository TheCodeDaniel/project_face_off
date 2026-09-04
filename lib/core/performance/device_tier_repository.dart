import 'package:shared_preferences/shared_preferences.dart';

import 'device_tier.dart';
import 'device_tier_service.dart';

/// Caches the resolved [DeviceTier] locally so it's computed once per
/// install, not on every launch ("at first launch, and cached" — Blueprint
/// Section 6) — same `shared_preferences`-backed pattern as
/// `LocalOnboardingRepository`'s "seen" flags.
class DeviceTierRepository {
  DeviceTierRepository(this._service);

  static const _prefsKey = 'device_tier';

  final DeviceTierService _service;

  Future<DeviceTier> resolveTier() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_prefsKey);
    if (cached != null) {
      return DeviceTier.values.asNameMap()[cached] ?? DeviceTier.mid;
    }

    final tier = await _service.resolveTier();
    await prefs.setString(_prefsKey, tier.name);
    return tier;
  }
}
