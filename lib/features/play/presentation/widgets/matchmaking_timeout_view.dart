import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../core/widgets/primary_pill_button.dart';

/// Friendly retry/cancel prompt shown once the queue times out (master
/// prompt Section 7) — never leaves the player in an indefinite spinner.
class MatchmakingTimeoutView extends StatelessWidget {
  const MatchmakingTimeoutView({super.key, required this.onRetry, required this.onCancel});

  final VoidCallback onRetry;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const AppIcon(HugeIcons.strokeRoundedUserSearch01, color: Colors.white, size: 64),
          const SizedBox(height: 24),
          Text('No opponent found', style: AppTextStyles.headline.copyWith(color: Colors.white)),
          const SizedBox(height: 8),
          Text(
            'Nobody was free to duel just now — want to try again?',
            style: AppTextStyles.body.copyWith(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          PrimaryPillButton(label: 'Try Again', icon: HugeIcons.strokeRoundedRefresh, onPressed: onRetry),
          const SizedBox(height: 12),
          SecondaryPillButton(label: 'Cancel', icon: HugeIcons.strokeRoundedCancelCircle, onPressed: onCancel),
        ],
      ),
    );
  }
}
