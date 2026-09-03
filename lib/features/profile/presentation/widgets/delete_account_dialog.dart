import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/lobby_palette.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../core/widgets/primary_pill_button.dart';

/// Confirmation for account deletion (master prompt Section 10) — must
/// actually delete the auth account and profile, not just sign out (Apple
/// requires real account deletion for App Store approval). This dialog only
/// confirms intent; the actual delete + Firestore profile removal happens in
/// `SettingsSection` once confirmed.
class DeleteAccountDialog extends StatelessWidget {
  const DeleteAccountDialog({super.key});

  static Future<bool> show(BuildContext context) async {
    final result = await showDialog<bool>(context: context, builder: (_) => const DeleteAccountDialog());
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
            const AppIcon(HugeIcons.strokeRoundedDelete02, color: Colors.red, size: 40),
            const SizedBox(height: 16),
            Text('Delete your account?', style: AppTextStyles.headline.copyWith(color: Colors.black87)),
            const SizedBox(height: 8),
            Text(
              'This permanently deletes your profile, stats, and cosmetics. This can\'t be undone.',
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(color: Colors.black54),
            ),
            const SizedBox(height: 24),
            PrimaryPillButton(label: 'Cancel', onPressed: () => Navigator.of(context).pop(false)),
            const SizedBox(height: 4),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete Account', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }
}
