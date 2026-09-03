import 'dart:math';

import 'package:flutter/material.dart';

import '../theme/app_text_styles.dart';
import '../theme/lobby_palette.dart';

/// App launch splash — plays once for [AppRoot]'s minimum-splash-duration
/// window (see `main.dart`). A single [AnimationController] drives
/// everything: a [CustomPainter] spiral of orbiting particles (cheap Canvas
/// draws, no per-particle widgets/rebuilds), the logo's scale-in +
/// counter-rotating settle, and a staggered per-letter reveal of "Face Off"
/// — all wrapped in one [RepaintBoundary] so this subtree's every-frame
/// repaint never touches the rest of the tree (engineering rule 6/7: no
/// heavy per-frame work on widget build, just Canvas ops and `Transform`).
class AnimatedSplashScreen extends StatefulWidget {
  const AnimatedSplashScreen({super.key});

  @override
  State<AnimatedSplashScreen> createState() => _AnimatedSplashScreenState();
}

class _AnimatedSplashScreenState extends State<AnimatedSplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..forward();

  static const _title = 'Face Off';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<LobbyPalette>() ?? LobbyPalette.standard;
    return Material(
      // Not Scaffold — this screen is swapped in and out by AppRoot's own
      // AnimatedSwitcher, so it doesn't need its own app-bar/floating-nav
      // slot. But Text still needs *some* Material ancestor, or it falls
      // back to WidgetsApp's debug default style — the loud yellow
      // double-underline under every word that shows up if you skip this.
      color: Colors.transparent,
      child: DecoratedBox(
        decoration: BoxDecoration(gradient: palette.backgroundGradient),
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final t = _controller.value;
              return Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _SpiralPainter(t: t, color: palette.coinGold),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _Logo(t: t, palette: palette),
                      const SizedBox(height: 22),
                      _StaggeredTitle(t: t, text: _title),
                      const SizedBox(height: 8),
                      Opacity(
                        opacity: (Curves.easeOut.transform(_clamp01((t - 0.7) / 0.3))),
                        child: Text(
                          'Face your friends. Don\'t flinch.',
                          style: AppTextStyles.label.copyWith(color: Colors.white70, letterSpacing: 0.3),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

double _clamp01(double v) => v.clamp(0.0, 1.0);

class _Logo extends StatelessWidget {
  const _Logo({required this.t, required this.palette});

  final double t;
  final LobbyPalette palette;

  @override
  Widget build(BuildContext context) {
    // Spirals inward and settles: starts spun-out/tiny/transparent, unwinds
    // to rest by ~65% through the timeline, then holds so the last third of
    // the animation is free for the title/tagline reveal to read clearly.
    final entrance = Curves.easeOutCubic.transform(_clamp01(t / 0.65));
    final scale = 0.3 + 0.7 * entrance;
    final spin = (1 - entrance) * 3 * pi;
    final opacity = _clamp01(t / 0.35);

    return Opacity(
      opacity: opacity,
      child: Transform.rotate(
        angle: spin,
        child: Transform.scale(
          scale: scale,
          child: Container(
            width: 108,
            height: 108,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.45), width: 1.6),
              boxShadow: [BoxShadow(color: palette.coinGold.withValues(alpha: 0.35 * entrance), blurRadius: 30)],
            ),
            padding: const EdgeInsets.all(18),
            child: ClipOval(child: Image.asset('assets/images/face-off-icon-1024.png', fit: BoxFit.cover)),
          ),
        ),
      ),
    );
  }
}

/// Reveals [text] letter-by-letter via an [Interval]-staggered slice of the
/// shared controller, each letter fading + sliding up into place — a single
/// `AnimatedBuilder` repaint per frame rather than one animation per letter.
class _StaggeredTitle extends StatelessWidget {
  const _StaggeredTitle({required this.t, required this.text});

  final double t;
  final String text;

  @override
  Widget build(BuildContext context) {
    const start = 0.45;
    const end = 0.85;
    final letters = text.characters.toList();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [for (var i = 0; i < letters.length; i++) _buildLetter(letters[i], i, letters.length, start, end)],
    );
  }

  Widget _buildLetter(String letter, int index, int count, double start, double end) {
    final span = (end - start) / count;
    final letterStart = start + span * index;
    final progress = Curves.easeOut.transform(_clamp01((t - letterStart) / span));
    return Opacity(
      opacity: progress,
      child: Transform.translate(
        offset: Offset(0, (1 - progress) * 14),
        child: Text(
          letter == ' ' ? ' ' : letter,
          style: AppTextStyles.display.copyWith(color: Colors.white, fontSize: 36),
        ),
      ),
    );
  }
}

/// Cheap decorative backdrop: a handful of particles spiraling inward
/// (radius + angle both animate with `t`) with a fading trail, drawn
/// directly on the [Canvas] — no per-particle `Widget`s, so this scales to
/// as many particles as look good without extra build/layout cost.
class _SpiralPainter extends CustomPainter {
  _SpiralPainter({required this.t, required this.color});

  final double t;
  final Color color;
  static const _particleCount = 18;

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0) return;
    final center = size.center(Offset.zero);
    final maxRadius = min(size.width, size.height) * 0.42;
    final paint = Paint()..style = PaintingStyle.fill;

    for (var i = 0; i < _particleCount; i++) {
      final seed = i / _particleCount;
      // Each particle's own progress is offset so they trail one another
      // rather than moving in lockstep — reads as a spiral, not a ring.
      final particleT = _clamp01((t - seed * 0.5) / 0.5);
      if (particleT <= 0 || particleT >= 1) continue;

      final eased = Curves.easeIn.transform(particleT);
      final angle = seed * 2 * pi + eased * 4 * pi;
      final radius = maxRadius * (1 - eased);
      final position = center + Offset(cos(angle), sin(angle)) * radius;
      final fade = sin(pi * particleT); // fades in, peaks mid-flight, fades out

      paint.color = color.withValues(alpha: 0.55 * fade);
      canvas.drawCircle(position, 2.5 + 2 * fade, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SpiralPainter oldDelegate) => oldDelegate.t != t;
}
