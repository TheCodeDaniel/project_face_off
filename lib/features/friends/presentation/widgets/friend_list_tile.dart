import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/lobby_palette.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../core/widgets/shimmer_card.dart';
import '../../domain/friend.dart';

/// One row in the friends list (master prompt Section 9): online/offline
/// indicator, avatar, display name, tap for a per-friend action sheet
/// (challenge/report/block/unfriend).
class FriendListTile extends StatelessWidget {
  const FriendListTile({super.key, required this.friend, required this.onTap});

  final Friend friend;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<LobbyPalette>() ?? LobbyPalette.standard;
    return ShimmerCard(
      margin: const EdgeInsets.only(bottom: 10),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: palette.gradientStart.withValues(alpha: 0.15),
                    child: Text(
                      friend.displayName.isEmpty ? '?' : friend.displayName.characters.first,
                      style: AppTextStyles.headline.copyWith(color: palette.gradientStart, fontSize: 16),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: friend.online ? const Color(0xFF4CD9E8) : Colors.black26,
                        border: Border.all(color: palette.cardBackground, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(friend.displayName, style: AppTextStyles.body.copyWith(color: Colors.black87)),
                    Text(
                      friend.online ? 'Online' : 'Offline',
                      style: AppTextStyles.label.copyWith(color: Colors.black45, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const AppIcon(HugeIcons.strokeRoundedMoreVertical, color: Colors.black38, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
