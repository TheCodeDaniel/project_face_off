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
      appBar: AppBar(backgroundColor: Colors.transparent, foregroundColor: Colors.white, elevation: 0),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          children: [
            Center(
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.18),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.4),
                ),
                alignment: Alignment.center,
                child: AppIcon(HugeIcons.strokeRoundedDiamond, color: palette.coinGold, size: 44),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Face Off Plus',
              textAlign: TextAlign.center,
              style: AppTextStyles.display.copyWith(color: Colors.white, fontSize: 30),
            ),
            const SizedBox(height: 6),
            Text(
              'Unlock the full experience',
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 28),
            for (final perk in _perks) _PerkCard(icon: perk.icon, text: perk.text, palette: palette),
            const SizedBox(height: 16),
            PrimaryPillButton(
              label: 'Subscriptions coming soon',
              icon: HugeIcons.strokeRoundedDiamond,
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Subscriptions need RevenueCat set up first — see CLAUDE.md.')),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Pricing and billing are handled by RevenueCat once it's configured — nothing to set up here yet.",
              textAlign: TextAlign.center,
              style: AppTextStyles.label.copyWith(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _PerkCard extends StatelessWidget {
  const _PerkCard({required this.icon, required this.text, required this.palette});

  final List<List<dynamic>> icon;
  final String text;
  final LobbyPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: palette.coinGold.withValues(alpha: 0.25), shape: BoxShape.circle),
            alignment: Alignment.center,
            child: AppIcon(icon, color: palette.coinGold, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(text, style: AppTextStyles.body.copyWith(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
