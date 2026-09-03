import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/gradient_scaffold.dart';
import '../../../core/widgets/stat_tile.dart';
import '../../app_shell/presentation/nav_visibility_controller.dart';

/// Profile tab (master prompt Section 10): header, stat grid, leaderboard,
/// subscription, cosmetics, settings. Firebase/RevenueCat data layers not
/// wired yet — see CLAUDE.md.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      body: SafeArea(
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
              Text('Profile', style: AppTextStyles.display.copyWith(color: Colors.white)),
              const SizedBox(height: 24),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.4,
                children: const [
                  StatTile(label: 'Win streak', value: '0', icon: HugeIcons.strokeRoundedFire),
                  StatTile(label: 'Matches', value: '0', icon: HugeIcons.strokeRoundedBoxingGlove01),
                  StatTile(label: 'Friends', value: '0', icon: HugeIcons.strokeRoundedUserGroup),
                  StatTile(label: 'Win rate', value: '0%', icon: HugeIcons.strokeRoundedAward01),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
