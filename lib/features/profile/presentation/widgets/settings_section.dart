import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/lobby_palette.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../core/widgets/shimmer_card.dart';
import '../../../auth/presentation/auth_providers.dart';
import '../faq_support_screen.dart';
import '../notification_settings_controller.dart';
import 'delete_account_dialog.dart';
import 'sign_out_dialog.dart';

/// Settings (master prompt Section 10): notification toggle, FAQ & support,
/// sign out, delete account.
class SettingsSection extends ConsumerWidget {
  const SettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = Theme.of(context).extension<LobbyPalette>() ?? LobbyPalette.standard;
    final notificationsEnabled = ref.watch(notificationSettingsControllerProvider).valueOrNull ?? true;

    return ShimmerCard(
      borderRadius: BorderRadius.circular(20),
      child: Column(
        children: [
          SwitchListTile(
            value: notificationsEnabled,
            onChanged: (v) => ref.read(notificationSettingsControllerProvider.notifier).setEnabled(v),
            activeThumbColor: palette.gradientMid,
            title: Text('Notifications', style: AppTextStyles.body.copyWith(color: Colors.black87)),
            secondary: const AppIcon(HugeIcons.strokeRoundedNotification01, color: Colors.black54, size: 20),
          ),
          _Row(
            icon: HugeIcons.strokeRoundedQuestion,
            label: 'FAQ & Support',
            // rootNavigator: true — see the note on ProfileScreen's
            // Leaderboard push; same nested-Navigator/nav-bar-bleed issue.
            onTap: () => Navigator.of(
              context,
              rootNavigator: true,
            ).push(MaterialPageRoute(builder: (_) => const FaqSupportScreen())),
          ),
          _Row(
            icon: HugeIcons.strokeRoundedLogout01,
            label: 'Sign Out',
            onTap: () async {
              final confirmed = await SignOutDialog.show(context);
              if (confirmed) await ref.read(authRepositoryProvider).signOut();
            },
          ),
          _Row(
            icon: HugeIcons.strokeRoundedDelete02,
            label: 'Delete Account',
            destructive: true,
            onTap: () async {
              final confirmed = await DeleteAccountDialog.show(context);
              if (confirmed) await ref.read(authRepositoryProvider).deleteAccount();
            },
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.label, required this.onTap, this.destructive = false});

  final List<List<dynamic>> icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? Colors.red.shade400 : Colors.black87;
    return ListTile(
      onTap: onTap,
      leading: AppIcon(icon, color: destructive ? Colors.red.shade400 : Colors.black54, size: 20),
      title: Text(label, style: AppTextStyles.body.copyWith(color: color)),
      trailing: const AppIcon(HugeIcons.strokeRoundedArrowRight01, color: Colors.black26, size: 16),
    );
  }
}
