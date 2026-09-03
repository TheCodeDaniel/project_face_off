import 'package:flutter/material.dart';

import '../theme/app_text_styles.dart';
import '../theme/lobby_palette.dart';
import 'app_icon.dart';
import 'primary_pill_button.dart';

/// Shared confirm/cancel dialog shell for lobby-register screens (light
/// card, not the dark match palette — see `QuitMatchDialog` for that
/// register). Used by `SignOutDialog` and `DeleteAccountDialog` so the two
/// don't duplicate the same icon/title/body/button structure. Demo:
/// ```dart
/// final confirmed = await LobbyConfirmationDialog.show(
///   context,
///   icon: HugeIcons.strokeRoundedDelete02,
///   iconColor: Colors.red,
///   title: 'Delete your account?',
///   message: "This can't be undone.",
///   confirmLabel: 'Delete Account',
/// );
/// ```
class LobbyConfirmationDialog extends StatelessWidget {
  const LobbyConfirmationDialog({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.message,
    required this.confirmLabel,
    this.cancelLabel = 'Cancel',
  });

  final List<List<dynamic>> icon;
  final Color iconColor;
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;

  static Future<bool> show(
    BuildContext context, {
    required List<List<dynamic>> icon,
    required Color iconColor,
    required String title,
    required String message,
    required String confirmLabel,
    String cancelLabel = 'Cancel',
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => LobbyConfirmationDialog(
        icon: icon,
        iconColor: iconColor,
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<LobbyPalette>() ?? LobbyPalette.standard;
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        decoration: BoxDecoration(color: palette.cardBackground, borderRadius: BorderRadius.circular(24)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon(icon, color: iconColor, size: 40),
            const SizedBox(height: 16),
            Text(title, style: AppTextStyles.headline.copyWith(color: Colors.black87)),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(color: Colors.black54),
            ),
            const SizedBox(height: 24),
            PrimaryPillButton(label: cancelLabel, onPressed: () => Navigator.of(context).pop(false)),
            const SizedBox(height: 4),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(confirmLabel, style: const TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }
}
