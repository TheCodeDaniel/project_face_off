import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local_notification_settings.dart';

final _localNotificationSettingsProvider = Provider((ref) => LocalNotificationSettings());

final notificationSettingsControllerProvider = AsyncNotifierProvider<NotificationSettingsController, bool>(
  NotificationSettingsController.new,
);

class NotificationSettingsController extends AsyncNotifier<bool> {
  @override
  Future<bool> build() => ref.watch(_localNotificationSettingsProvider).isEnabled();

  Future<void> setEnabled(bool enabled) async {
    state = AsyncData(enabled);
    await ref.read(_localNotificationSettingsProvider).setEnabled(enabled);
  }
}
