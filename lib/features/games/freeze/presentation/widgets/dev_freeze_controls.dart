import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../../core/game_engine/match_controller.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/widgets/app_icon.dart';

/// **Temporary local test harness** standing in for the real per-frame
/// landmark-delta stream (multi-game plan Section 2.3) — a single "Move!"
/// button per player sends one motion sample comfortably above
/// [FreezeRules.motionThreshold]. Delete once a real gesture engine feeds
/// [FreezeGameModule] motion samples directly.
class DevFreezeControls extends StatelessWidget {
  const DevFreezeControls({super.key, required this.opponentLabel, required this.onMove});

  final String opponentLabel;
  final void Function(String playerId) onMove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.55), borderRadius: BorderRadius.circular(16)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Dev freeze controls — no camera yet',
            style: AppTextStyles.label.copyWith(color: Colors.white54, fontSize: 11),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _PlayerControl(label: 'You', playerId: MatchController.meId, onMove: onMove),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _PlayerControl(label: opponentLabel, playerId: MatchController.opponentId, onMove: onMove),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlayerControl extends StatelessWidget {
  const _PlayerControl({required this.label, required this.playerId, required this.onMove});

  final String label;
  final String playerId;
  final void Function(String playerId) onMove;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: AppTextStyles.label.copyWith(color: Colors.white70)),
        const SizedBox(height: 6),
        Tooltip(
          message: 'Move',
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: () => onMove(playerId),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.14), shape: BoxShape.circle),
              alignment: Alignment.center,
              child: const AppIcon(HugeIcons.strokeRoundedWalking, color: Colors.white, size: 20),
            ),
          ),
        ),
      ],
    );
  }
}
