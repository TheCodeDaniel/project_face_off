import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_icon.dart';
import '../duel_controller.dart';

/// **Temporary local test harness** standing in for the real gesture engine
/// and opponent networking (master prompt Section 8.6 / 8.5) — neither
/// exists yet, see CLAUDE.md. Lets both sides of a duel be driven manually
/// from one device so the round state machine is genuinely playable and
/// demoable today. Delete this whole widget once `core/gesture_engine/`
/// has a real MediaPipe implementation and Realtime DB signaling replaces
/// [DuelController]'s local timers.
class DevGestureControls extends StatelessWidget {
  const DevGestureControls({
    super.key,
    required this.opponentLabel,
    required this.onFire,
    required this.onDodge,
    required this.onCrack,
  });

  final String opponentLabel;
  final void Function(String playerId) onFire;
  final void Function(String playerId) onDodge;
  final void Function(String playerId) onCrack;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.55), borderRadius: BorderRadius.circular(16)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Dev gesture controls — no camera yet',
            style: AppTextStyles.label.copyWith(color: Colors.white54, fontSize: 11),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _PlayerControls(
                  label: 'You',
                  playerId: DuelController.meId,
                  onFire: onFire,
                  onDodge: onDodge,
                  onCrack: onCrack,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _PlayerControls(
                  label: opponentLabel,
                  playerId: DuelController.opponentId,
                  onFire: onFire,
                  onDodge: onDodge,
                  onCrack: onCrack,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlayerControls extends StatelessWidget {
  const _PlayerControls({
    required this.label,
    required this.playerId,
    required this.onFire,
    required this.onDodge,
    required this.onCrack,
  });

  final String label;
  final String playerId;
  final void Function(String playerId) onFire;
  final void Function(String playerId) onDodge;
  final void Function(String playerId) onCrack;

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
            _GestureButton(icon: HugeIcons.strokeRoundedFlash, tooltip: 'Fire', onTap: () => onFire(playerId)),
            _GestureButton(icon: HugeIcons.strokeRoundedWink, tooltip: 'Dodge', onTap: () => onDodge(playerId)),
            _GestureButton(icon: HugeIcons.strokeRoundedSmile, tooltip: 'Crack', onTap: () => onCrack(playerId)),
          ],
        ),
      ],
    );
  }
}

class _GestureButton extends StatelessWidget {
  const _GestureButton({required this.icon, required this.tooltip, required this.onTap});

  final List<List<dynamic>> icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.14), shape: BoxShape.circle),
          alignment: Alignment.center,
          child: AppIcon(icon, color: Colors.white, size: 18),
        ),
      ),
    );
  }
}
