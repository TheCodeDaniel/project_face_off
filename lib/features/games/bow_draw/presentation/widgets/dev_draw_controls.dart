import 'package:flutter/material.dart';

import '../../../../../core/game_engine/match_controller.dart';
import '../../../../../core/theme/app_text_styles.dart';

/// **Temporary local test harness** standing in for the real Hand Landmarker
/// pipeline (game/UI/backend guideline Section 2) — a vertical drag per
/// player stands in for real hand pull-back distance, calling [onDrawUpdate]
/// continuously while dragging (exercising the same continuous-power path
/// the real gesture engine's `DrawUpdate` events will drive) and [onShoot]
/// on release, carrying whatever power the drag reached. Delete once the
/// real hand-gesture engine replaces this.
class DevDrawControls extends StatelessWidget {
  const DevDrawControls({super.key, required this.opponentLabel, required this.onDrawUpdate, required this.onShoot});

  final String opponentLabel;
  final void Function(String playerId, double power) onDrawUpdate;
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
                child: _PullControl(
                  label: 'You',
                  playerId: MatchController.meId,
                  onDrawUpdate: onDrawUpdate,
                  onShoot: onShoot,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _PullControl(
                  label: opponentLabel,
                  playerId: MatchController.opponentId,
                  onDrawUpdate: onDrawUpdate,
                  onShoot: onShoot,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PullControl extends StatefulWidget {
  const _PullControl({required this.label, required this.playerId, required this.onDrawUpdate, required this.onShoot});

  final String label;
  final String playerId;
  final void Function(String playerId, double power) onDrawUpdate;
  final void Function(String playerId, double power) onShoot;

  @override
  State<_PullControl> createState() => _PullControlState();
}

class _PullControlState extends State<_PullControl> {
  static const _trackHeight = 72.0;

  double _power = 0;

  void _updatePower(double localDy) {
    final power = (localDy / _trackHeight).clamp(0.0, 1.0);
    setState(() => _power = power);
    widget.onDrawUpdate(widget.playerId, power);
  }

  void _release() {
    widget.onShoot(widget.playerId, _power);
    setState(() => _power = 0);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(widget.label, style: AppTextStyles.label.copyWith(color: Colors.white70)),
        const SizedBox(height: 6),
        GestureDetector(
          onVerticalDragUpdate: (details) => _updatePower(details.localPosition.dy),
          onVerticalDragEnd: (_) => _release(),
          onVerticalDragCancel: () => setState(() => _power = 0),
          child: Container(
            width: 44,
            height: _trackHeight,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.bottomCenter,
            child: FractionallySizedBox(
              heightFactor: _power,
              widthFactor: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text('${(_power * 100).round()}%', style: AppTextStyles.label.copyWith(color: Colors.white54, fontSize: 11)),
      ],
    );
  }
}
