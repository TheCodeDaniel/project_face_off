import 'package:flutter/material.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/lobby_palette.dart';
import '../../domain/player_profile.dart';

/// Profile header (master prompt Section 10): avatar, display name,
/// level/tier bar (Blueprint Section 1, dark rewards hub reference).
class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key, required this.profile});

  final PlayerProfile profile;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<LobbyPalette>() ?? LobbyPalette.standard;
    return Column(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundColor: Colors.white,
          child: Text(
            profile.displayName.isEmpty ? '?' : profile.displayName.characters.first,
            style: AppTextStyles.display.copyWith(color: palette.gradientStart, fontSize: 32),
          ),
        ),
        const SizedBox(height: 10),
        Text(profile.displayName, style: AppTextStyles.headline.copyWith(color: Colors.white)),
        const SizedBox(height: 8),
        SizedBox(
          width: 180,
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: profile.tierProgress.clamp(0, 1),
                  minHeight: 6,
                  backgroundColor: Colors.white.withValues(alpha: 0.25),
                  valueColor: AlwaysStoppedAnimation(palette.coinGold),
                ),
              ),
              const SizedBox(height: 4),
              Text(profile.tierLabel, style: AppTextStyles.label.copyWith(color: Colors.white70)),
            ],
          ),
        ),
      ],
    );
  }
}
