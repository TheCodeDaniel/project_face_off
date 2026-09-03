import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../core/widgets/lobby_confirmation_dialog.dart';

/// Confirmation for account deletion (master prompt Section 10) — must
/// actually delete the auth account and profile, not just sign out (Apple
/// requires real account deletion for App Store approval). This dialog only
/// confirms intent; the actual delete + Firestore profile removal happens in
/// `SettingsSection` once confirmed.
class DeleteAccountDialog {
  DeleteAccountDialog._();

  static Future<bool> show(BuildContext context) {
    return LobbyConfirmationDialog.show(
      context,
      icon: HugeIcons.strokeRoundedDelete02,
      iconColor: Colors.red,
      title: 'Delete your account?',
      message: "This permanently deletes your profile, stats, and cosmetics. This can't be undone.",
      confirmLabel: 'Delete Account',
    );
  }
}
