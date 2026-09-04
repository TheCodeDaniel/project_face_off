import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/lobby_palette.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../domain/friend_request.dart';

/// Incoming friend request row (master prompt Section 9): accept/decline.
class FriendRequestTile extends StatelessWidget {
  const FriendRequestTile({super.key, required this.request, required this.onAccept, required this.onDecline});

  final FriendRequest request;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<LobbyPalette>() ?? LobbyPalette.standard;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: palette.coinGold.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.coinGold.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: palette.coinGold.withValues(alpha: 0.3),
            child: Text(
              request.fromDisplayName.isEmpty ? '?' : request.fromDisplayName.characters.first,
              style: AppTextStyles.headline.copyWith(color: Colors.black87, fontSize: 15),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${request.fromDisplayName} wants to be friends',
              style: AppTextStyles.body.copyWith(color: Colors.black87),
            ),
          ),
          _RoundIconButton(
            icon: HugeIcons.strokeRoundedCheckmarkCircle02,
            color: const Color(0xFF2FAE66),
            onTap: onAccept,
          ),
          const SizedBox(width: 6),
          _RoundIconButton(icon: HugeIcons.strokeRoundedCancelCircle, color: Colors.black45, onTap: onDecline),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.color, required this.onTap});

  final List<List<dynamic>> icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: AppIcon(icon, color: color, size: 22),
      ),
    );
  }
}
