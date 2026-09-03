import 'package:flutter/material.dart';

import '../theme/app_text_styles.dart';
import '../theme/lobby_palette.dart';

/// Card-based room-browser entry (Blueprint Section 1, Image 2): category chip,
/// stacked-avatar occupants, capacity, CTA pill. Demo:
/// ```dart
/// RoomCard(
///   categoryEmoji: '🎭', categoryLabel: 'Casual',
///   occupantAvatarUrls: const ['a.png', 'b.png'],
///   occupied: 6, capacity: 8, onJoin: () {},
/// )
/// ```
class RoomCard extends StatelessWidget {
  const RoomCard({
    super.key,
    required this.categoryEmoji,
    required this.categoryLabel,
    required this.occupantAvatarUrls,
    required this.occupied,
    required this.capacity,
    required this.onJoin,
  });

  final String categoryEmoji;
  final String categoryLabel;
  final List<String> occupantAvatarUrls;
  final int occupied;
  final int capacity;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<LobbyPalette>() ?? LobbyPalette.standard;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.cardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: palette.gradientStart.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(categoryEmoji),
                const SizedBox(width: 4),
                Text(categoryLabel, style: AppTextStyles.label.copyWith(color: palette.gradientStart)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StackedAvatars(avatarUrls: occupantAvatarUrls),
                const SizedBox(height: 4),
                Text('($occupied/$capacity)', style: AppTextStyles.label.copyWith(color: Colors.black54)),
              ],
            ),
          ),
          PrimaryPillButtonCompact(label: 'Join', onPressed: onJoin),
        ],
      ),
    );
  }
}

class _StackedAvatars extends StatelessWidget {
  const _StackedAvatars({required this.avatarUrls});

  final List<String> avatarUrls;

  @override
  Widget build(BuildContext context) {
    const size = 24.0;
    final shown = avatarUrls.take(4).toList();
    return SizedBox(
      height: size,
      width: size + (shown.length - 1) * 16 + 4,
      child: Stack(
        children: [
          for (var i = 0; i < shown.length; i++)
            Positioned(
              left: i * 16.0,
              child: CircleAvatar(
                radius: size / 2,
                backgroundColor: Colors.grey.shade300,
                child: const Icon(Icons.person, size: 14, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}

/// Compact CTA pill for inline use inside a [RoomCard] row.
class PrimaryPillButtonCompact extends StatelessWidget {
  const PrimaryPillButtonCompact({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<LobbyPalette>() ?? LobbyPalette.standard;
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: palette.gradientMid,
        foregroundColor: Colors.white,
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      ),
      child: Text(label, style: AppTextStyles.label.copyWith(color: Colors.white)),
    );
  }
}
