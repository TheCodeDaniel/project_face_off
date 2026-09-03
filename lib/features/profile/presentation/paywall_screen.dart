import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/lobby_palette.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/gradient_scaffold.dart';
import '../../../core/widgets/primary_pill_button.dart';

/// Face Off Plus paywall (master prompt Section 11), triggered from
/// [SubscriptionSection] or any gated feature's natural touchpoint. Product
/// catalog and purchase flow need RevenueCat API keys + an Offerings
/// catalog configured in their dashboard first — see CLAUDE.md. This screen
/// is the real UI, just without a live purchase button wired to it yet.
class PaywallScreen extends StatelessWidget {
  const PaywallScreen({super.key});

  static const _perks = [
    (icon: HugeIcons.strokeRoundedVideo01, text: 'HD, watermark-free clip export'),
    (icon: HugeIcons.strokeRoundedDoorOpen, text: 'Unlimited private rooms'),
    (icon: HugeIcons.strokeRoundedGift, text: 'Early access to new cosmetics'),
  ];

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<LobbyPalette>() ?? LobbyPalette.standard;
    return GradientScaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, foregroundColor: Colors.white),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(),
              AppIcon(HugeIcons.strokeRoundedDiamond, color: palette.coinGold, size: 56),
              const SizedBox(height: 16),
              Text('Face Off Plus', style: AppTextStyles.display.copyWith(color: Colors.white)),
              const SizedBox(height: 24),
              for (final perk in _perks) _PerkRow(icon: perk.icon, text: perk.text),
              const Spacer(),
              PrimaryPillButton(
                label: 'Subscriptions coming soon',
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Subscriptions need RevenueCat set up first — see CLAUDE.md.')),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _PerkRow extends StatelessWidget {
  const _PerkRow({required this.icon, required this.text});

  final List<List<dynamic>> icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          AppIcon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: AppTextStyles.body.copyWith(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
