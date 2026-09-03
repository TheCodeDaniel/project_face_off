import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/lobby_palette.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../domain/cosmetic.dart';
import '../profile_providers.dart';

/// Cosmetics/inventory (master prompt Section 10): owned skins/effects,
/// equip/unequip. Locked (unowned) cosmetics show a lock overlay rather than
/// being hidden — discoverability for the store, per Blueprint Section 4's
/// "badge, not popup" monetization philosophy.
class CosmeticsSection extends ConsumerWidget {
  const CosmeticsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cosmetics = ref.watch(cosmeticsProvider).valueOrNull ?? const <Cosmetic>[];
    if (cosmetics.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: cosmetics.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, i) => _CosmeticTile(cosmetic: cosmetics[i]),
      ),
    );
  }
}

class _CosmeticTile extends ConsumerWidget {
  const _CosmeticTile({required this.cosmetic});

  final Cosmetic cosmetic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = Theme.of(context).extension<LobbyPalette>() ?? LobbyPalette.standard;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: cosmetic.owned ? () => ref.read(profileRepositoryProvider).equipCosmetic(cosmetic.id) : null,
      child: Container(
        width: 80,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: palette.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: cosmetic.equipped ? Border.all(color: palette.gradientMid, width: 2) : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                AppIcon(cosmetic.icon, color: cosmetic.owned ? palette.gradientStart : Colors.black26, size: 28),
                if (!cosmetic.owned)
                  const Positioned(
                    right: -4,
                    bottom: -4,
                    child: AppIcon(HugeIcons.strokeRoundedLocked, color: Colors.black45, size: 14),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              cosmetic.name,
              style: AppTextStyles.label.copyWith(color: Colors.black87, fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
