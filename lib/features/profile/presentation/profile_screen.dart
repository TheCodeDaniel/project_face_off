import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/gradient_scaffold.dart';
import '../../../core/widgets/stat_tile.dart';
import '../../app_shell/presentation/nav_visibility_controller.dart';
import 'leaderboard_screen.dart';
import 'profile_providers.dart';
import 'widgets/cosmetics_section.dart';
import 'widgets/per_game_stats_sheet.dart';
import 'widgets/profile_header.dart';
import 'widgets/settings_section.dart';
import 'widgets/subscription_section.dart';

/// Profile tab (master prompt Section 10): header, stat grid, leaderboard,
/// subscription, cosmetics, settings.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(playerProfileProvider).valueOrNull;

    return GradientScaffold(
      body: SafeArea(
        bottom: false,
        child: NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification is ScrollUpdateNotification) {
              NavVisibilityScope.of(context).onScrollDelta(notification.scrollDelta ?? 0);
            }
            return false;
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
            children: [
              if (profile != null) ProfileHeader(profile: profile),
              const SizedBox(height: 24),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.4,
                children: [
                  StatTile(label: 'Win streak', value: '${profile?.winStreak ?? 0}', icon: HugeIcons.strokeRoundedFire),
                  StatTile(
                    label: 'Matches',
                    value: '${profile?.totalMatches ?? 0}',
                    icon: HugeIcons.strokeRoundedBoxingGlove01,
                  ),
                  StatTile(
                    label: 'Friends',
                    value: '${profile?.friendsCount ?? 0}',
                    icon: HugeIcons.strokeRoundedUserGroup,
                  ),
                  StatTile(
                    label: 'Win rate',
                    value: '${profile?.winRatePercent ?? 0}%',
                    icon: HugeIcons.strokeRoundedAward01,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _NavCard(
                icon: HugeIcons.strokeRoundedChartBreakoutSquare,
                label: 'Stats by game',
                onTap: () => PerGameStatsSheet.show(context, profile?.perGameStats ?? const {}),
              ),
              const SizedBox(height: 12),
              _NavCard(
                icon: HugeIcons.strokeRoundedPodium,
                label: 'Leaderboard',
                // rootNavigator: true — the Profile tab has its own nested
                // Navigator (Section 5's per-tab back-stack), which
                // FloatingNavBar paints over; see CLAUDE.md engineering rule
                // 9. Without this the nav bar bleeds through the pushed page.
                onTap: () => Navigator.of(
                  context,
                  rootNavigator: true,
                ).push(MaterialPageRoute(builder: (_) => const LeaderboardScreen())),
              ),
              const SizedBox(height: 24),
              Text('Cosmetics', style: AppTextStyles.label.copyWith(color: Colors.white70)),
              const SizedBox(height: 10),
              const CosmeticsSection(),
              const SizedBox(height: 24),
              const SubscriptionSection(),
              const SizedBox(height: 24),
              const SettingsSection(),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavCard extends StatelessWidget {
  const _NavCard({required this.icon, required this.label, required this.onTap});

  final List<List<dynamic>> icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              AppIcon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(label, style: AppTextStyles.body.copyWith(color: Colors.white)),
              ),
              const AppIcon(HugeIcons.strokeRoundedArrowRight01, color: Colors.white70, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
