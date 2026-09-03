import 'package:flutter/material.dart';

import '../theme/app_text_styles.dart';
import '../theme/match_palette.dart';

/// The dramatic pre-match beat (Blueprint Section 1, Image 6 / rock-paper-
/// scissors reference): two avatars slide in from opposite edges, collide at a
/// "VS" mark with a camera-shake-style micro animation, then a countdown
/// starts. The duel feature triggers this precisely once both players are
/// confirmed connected, via [controller]. Demo:
/// ```dart
/// final controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
/// DuelVsTransition(controller: controller, leftLabel: 'You', rightLabel: 'Ama', onComplete: () {});
/// ```
class DuelVsTransition extends StatefulWidget {
  const DuelVsTransition({
    super.key,
    required this.controller,
    required this.leftLabel,
    required this.rightLabel,
    this.onComplete,
  });

  final AnimationController controller;
  final String leftLabel;
  final String rightLabel;
  final VoidCallback? onComplete;

  @override
  State<DuelVsTransition> createState() => _DuelVsTransitionState();
}

class _DuelVsTransitionState extends State<DuelVsTransition> {
  @override
  void initState() {
    super.initState();
    widget.controller.forward(from: 0);
    widget.controller.addStatusListener(_onStatus);
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) widget.onComplete?.call();
  }

  @override
  void dispose() {
    widget.controller.removeStatusListener(_onStatus);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<MatchPalette>() ?? MatchPalette.standard;
    final slideIn = CurvedAnimation(
      parent: widget.controller,
      curve: const Interval(0, 0.7, curve: Curves.easeOutBack),
    );
    final shake = CurvedAnimation(
      parent: widget.controller,
      curve: const Interval(0.7, 0.85, curve: Curves.elasticIn),
    );

    return DecoratedBox(
      decoration: BoxDecoration(gradient: palette.backgroundGradient),
      child: AnimatedBuilder(
        animation: widget.controller,
        builder: (context, _) {
          final shakeOffset = Offset(8 * (1 - shake.value) * ((shake.value * 20).floor().isEven ? 1 : -1), 0);
          return Stack(
            alignment: Alignment.center,
            children: [
              Transform.translate(
                offset: Offset(-300 * (1 - slideIn.value) + shakeOffset.dx, 0),
                child: _CombatantLabel(label: widget.leftLabel, color: palette.neonViolet),
              ),
              Transform.translate(
                offset: Offset(300 * (1 - slideIn.value) - shakeOffset.dx, 0),
                child: _CombatantLabel(label: widget.rightLabel, color: palette.neonCyan),
              ),
              Opacity(
                opacity: slideIn.value.clamp(0, 1),
                child: Text('VS', style: AppTextStyles.display.copyWith(color: Colors.white, fontSize: 44)),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CombatantLabel extends StatelessWidget {
  const _CombatantLabel({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: color,
            child: const Icon(Icons.face_rounded, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppTextStyles.headline.copyWith(color: Colors.white),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
