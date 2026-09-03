import 'package:shared_preferences/shared_preferences.dart';

/// Device-local notification preference (master prompt Section 10) — a
/// device setting, not user-profile data, so it's kept separate from
/// [ProfileRepository] the same way onboarding state is kept separate from
/// auth. No push-notification wiring exists yet; this only persists the
/// toggle itself.
class LocalNotificationSettings {
  static const _key = 'notifications_enabled';

  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? true;
  }

  Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, enabled);
  }
}
