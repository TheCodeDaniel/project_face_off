import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../core/widgets/lobby_confirmation_dialog.dart';

/// Confirmation before signing out — a bare tap-to-sign-out with no
/// confirmation is an easy accidental tap to regret, especially since
/// there's no "undo" for it.
class SignOutDialog {
  SignOutDialog._();

  static Future<bool> show(BuildContext context) {
    return LobbyConfirmationDialog.show(
      context,
      icon: HugeIcons.strokeRoundedLogout01,
      iconColor: Colors.red,
      title: 'Sign out?',
      message: "You'll need to sign back in to play again.",
      confirmLabel: 'Sign Out',
    );
  }
}
