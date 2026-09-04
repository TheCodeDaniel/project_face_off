import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../theme/app_text_styles.dart';
import '../theme/match_palette.dart';
import 'app_icon.dart';

/// The dramatic pre-match beat (Blueprint Section 1, Image 6 / rock-paper-
/// scissors reference): two avatars slide in from opposite edges and collide
/// at a "VS" mark with a soft impact flash and a brief, smoothly-decaying
/// camera shake, then a countdown starts. The duel feature triggers this
/// precisely once both players are confirmed connected, via [controller].
///
/// The shake is a continuous decaying sine wave, not a toggled offset — a
/// discrete on/off jitter reads as janky rather than a real camera-shake
/// impact. Demo:
/// ```dart
/// final controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
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

  /// Smooth 0→1→0 bump centered on the collision moment — used to shape the
  /// shake, the impact flash, and the avatar "punch" scale so they all peak
  /// together instead of drifting independently.
  static double _impactEnvelope(double t) {
    const start = 0.48, end = 0.82;
    if (t < start || t > end) return 0;
    return math.sin((t - start) / (end - start) * math.pi);
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<MatchPalette>() ?? MatchPalette.standard;
    final slideIn = CurvedAnimation(
      parent: widget.controller,
      curve: const Interval(0, 0.6, curve: Curves.easeOutCubic),
    );
    final vsPop = CurvedAnimation(
      parent: widget.controller,
      curve: const Interval(0.48, 0.88, curve: Curves.elasticOut),
    );

    return DecoratedBox(
      decoration: BoxDecoration(gradient: palette.backgroundGradient),
      child: AnimatedBuilder(
        animation: widget.controller,
        builder: (context, _) {
          final t = widget.controller.value;
          final envelope = _impactEnvelope(t);
          final shakeX = math.sin(t * 46) * 5 * envelope;
          final shakeY = math.sin(t * 63 + 1.2) * 2.5 * envelope;
          final punch = 1 + 0.1 * envelope;

          return Transform.translate(
            offset: Offset(shakeX, shakeY),
            child: Stack(
              alignment: Alignment.center,
              children: [
                _ImpactFlash(strength: envelope, color: palette.neonCyan),
                Transform.translate(
                  offset: Offset(-260 * (1 - slideIn.value), 0),
                  child: Transform.scale(
                    scale: punch,
                    child: _CombatantLabel(label: widget.leftLabel, color: palette.neonViolet),
                  ),
                ),
                Transform.translate(
                  offset: Offset(260 * (1 - slideIn.value), 0),
                  child: Transform.scale(
                    scale: punch,
                    child: _CombatantLabel(label: widget.rightLabel, color: palette.neonCyan),
                  ),
                ),
                Transform.scale(
                  scale: 0.4 + 0.6 * vsPop.value,
                  child: Text(
                    'VS',
                    // Alpha baked into the color instead of an Opacity
                    // wrapper — Opacity forces an offscreen saveLayer per
                    // instance, and this widget already animates several
                    // other things (shake, scale, the impact flash) in the
                    // same frame; see AnimatedSplashScreen's doc comment
                    // for the compositing issue that pattern caused there.
                    style: AppTextStyles.display.copyWith(
                      color: Colors.white.withValues(alpha: slideIn.value.clamp(0, 1)),
                      fontSize: 44,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Soft radial burst at the collision moment — reads as "impact" without
/// relying on screen jitter to sell it.
class _ImpactFlash extends StatelessWidget {
  const _ImpactFlash({required this.strength, required this.color});

  final double strength;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (strength <= 0) return const SizedBox.shrink();
    return IgnorePointer(
      child: Container(
        width: 160 + 220 * strength,
        height: 160 + 220 * strength,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: 0.35 * strength),
              color.withValues(alpha: 0),
            ],
          ),
        ),
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
            child: const AppIcon(HugeIcons.strokeRoundedUserCircle02, color: Colors.white, size: 30),
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
