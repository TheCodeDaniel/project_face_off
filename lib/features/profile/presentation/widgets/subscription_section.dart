import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/lobby_palette.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../core/widgets/primary_pill_button.dart';
import '../../domain/subscription_tier.dart';
import '../paywall_screen.dart';
import '../profile_providers.dart';

/// Subscription section (master prompt Section 11, surfaced from Profile):
/// current tier, upgrade entry point, manage/restore. RevenueCat isn't wired
/// up yet — see CLAUDE.md and `PaywallScreen`.
class SubscriptionSection extends ConsumerWidget {
  const SubscriptionSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = Theme.of(context).extension<LobbyPalette>() ?? LobbyPalette.standard;
    final tier = ref.watch(subscriptionTierProvider).valueOrNull ?? SubscriptionTier.free;
    final isPlus = tier == SubscriptionTier.plus;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: palette.cardBackground, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppIcon(HugeIcons.strokeRoundedDiamond, color: isPlus ? palette.coinGold : Colors.black45, size: 20),
              const SizedBox(width: 8),
              Text('Subscription', style: AppTextStyles.headline.copyWith(color: Colors.black87, fontSize: 16)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isPlus ? palette.coinGold.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  tier.label,
                  style: AppTextStyles.label.copyWith(color: isPlus ? Colors.black87 : Colors.black45, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (!isPlus)
            PrimaryPillButton(
              label: 'Upgrade to Face Off Plus',
              icon: HugeIcons.strokeRoundedDiamond,
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PaywallScreen())),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => _showManageInfo(context),
                  child: Text('Manage Subscription', style: AppTextStyles.label.copyWith(color: palette.gradientStart)),
                ),
              ),
              Expanded(
                child: TextButton(
                  onPressed: () => _restore(context, ref),
                  child: Text('Restore Purchases', style: AppTextStyles.label.copyWith(color: palette.gradientStart)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showManageInfo(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Manage your subscription from the App Store / Play Store settings.')));
  }

  Future<void> _restore(BuildContext context, WidgetRef ref) async {
    await ref.read(profileRepositoryProvider).restorePurchases();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No previous purchases found.')));
    }
  }
}
