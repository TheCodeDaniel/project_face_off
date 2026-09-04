import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../../core/game_engine/match_controller.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/widgets/app_icon.dart';

/// **Temporary local test harness** standing in for the real Hand Landmarker
/// pipeline (multi-game plan Section 2.2) — three preset draw-power buttons
/// per player (light/medium/full pull) in place of tracking real hand
/// distance. Delete once the real hand-gesture engine replaces this.
class DevDrawControls extends StatelessWidget {
  const DevDrawControls({super.key, required this.opponentLabel, required this.onShoot});

  final String opponentLabel;
  final void Function(String playerId, double power) onShoot;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.55), borderRadius: BorderRadius.circular(16)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Dev draw controls — no camera yet',
            style: AppTextStyles.label.copyWith(color: Colors.white54, fontSize: 11),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _PlayerControls(label: 'You', playerId: MatchController.meId, onShoot: onShoot),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _PlayerControls(label: opponentLabel, playerId: MatchController.opponentId, onShoot: onShoot),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlayerControls extends StatelessWidget {
  const _PlayerControls({required this.label, required this.playerId, required this.onShoot});

  final String label;
  final String playerId;
  final void Function(String playerId, double power) onShoot;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: AppTextStyles.label.copyWith(color: Colors.white70)),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _ShotButton(label: 'Light', power: 0.3, onTap: () => onShoot(playerId, 0.3)),
            _ShotButton(label: 'Medium', power: 0.6, onTap: () => onShoot(playerId, 0.6)),
            _ShotButton(label: 'Full', power: 0.9, onTap: () => onShoot(playerId, 0.9)),
          ],
        ),
      ],
    );
  }
}

class _ShotButton extends StatelessWidget {
  const _ShotButton({required this.label, required this.power, required this.onTap});

  final String label;
  final double power;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: '$label pull',
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.14), shape: BoxShape.circle),
          alignment: Alignment.center,
          child: const AppIcon(HugeIcons.strokeRoundedTarget03, color: Colors.white, size: 18),
        ),
      ),
    );
  }
}
