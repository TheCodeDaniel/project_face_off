import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:showcaseview/showcaseview.dart';

import '../../../core/onboarding_tour/tour_keys.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/coin_badge.dart';
import '../../../core/widgets/gradient_scaffold.dart';
import '../../../core/widgets/primary_pill_button.dart';
import '../../app_shell/presentation/nav_visibility_controller.dart';

/// Play tab home state (master prompt Section 7): live "players online now"
/// indicator, Quick Match CTA, How to Play, recent match history teaser.
/// Matchmaking-queue flow and Firestore/Realtime DB pairing are not wired yet
/// — see CLAUDE.md.
class PlayScreen extends StatelessWidget {
  const PlayScreen({super.key});

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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Face Off', style: AppTextStyles.display.copyWith(color: Colors.white)),
                  const CoinBadge(coins: 0),
                ],
              ),
              const SizedBox(height: 24),
              const _OnlineIndicator(count: 0),
              const SizedBox(height: 32),
              Showcase(
                key: TourKeys.quickMatch,
                title: 'Quick Match',
                description: 'Jump into a random duel the moment you\'re ready.',
                targetBorderRadius: BorderRadius.circular(999),
                child: PrimaryPillButton(label: 'Quick Match', icon: HugeIcons.strokeRoundedZap, onPressed: () {}),
              ),
              const SizedBox(height: 12),
              SecondaryPillButton(label: 'How to Play', icon: HugeIcons.strokeRoundedHelpCircle, onPressed: () {}),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnlineIndicator extends StatelessWidget {
  const _OnlineIndicator({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(color: Color(0xFF4CD9E8), shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text('$count players online now', style: AppTextStyles.label.copyWith(color: Colors.white70)),
      ],
    );
  }
}
