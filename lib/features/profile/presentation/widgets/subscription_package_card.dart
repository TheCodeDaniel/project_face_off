import 'package:flutter/material.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/lobby_palette.dart';
import '../../domain/subscription_package.dart';

/// One selectable plan in the paywall's package picker — a radio-style card
/// (border + coin-gold badge when selected) rather than a plain price list,
/// so the monthly/annual choice reads as a deliberate pick.
class SubscriptionPackageCard extends StatelessWidget {
  const SubscriptionPackageCard({super.key, required this.package, required this.selected, required this.onTap});

  final SubscriptionPackage package;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<LobbyPalette>() ?? LobbyPalette.standard;
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: selected ? Colors.white.withValues(alpha: 0.22) : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: selected ? palette.coinGold : Colors.white.withValues(alpha: 0.25), width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (package.badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: palette.coinGold, borderRadius: BorderRadius.circular(999)),
                child: Text(package.badge!, style: AppTextStyles.label.copyWith(color: Colors.black87, fontSize: 10)),
              )
            else
              const SizedBox(height: 19),
            const SizedBox(height: 8),
            Text(package.title, style: AppTextStyles.body.copyWith(color: Colors.white70)),
            const SizedBox(height: 2),
            Text(package.priceLabel, style: AppTextStyles.headline.copyWith(color: Colors.white, fontSize: 18)),
          ],
        ),
      ),
    );
  }
}
