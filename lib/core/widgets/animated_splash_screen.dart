import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../theme/app_text_styles.dart';
import '../theme/match_palette.dart';

/// App launch splash — a Netflix-style logo sting: near-black cinematic
/// background, the app icon punches in with a bouncy scale-and-settle, the
/// "FACE OFF" wordmark fades up beneath it, then a single diagonal shine
/// sweeps across the whole lockup once.
///
/// One [AnimationController] drives every phase; deliberately **no
/// [Opacity] widgets** — every fade is baked into a color's alpha instead
/// (`color.withValues(alpha: ...)`), and the shine sweep is the same
/// translucent-gradient-overlay technique as `ShimmerCard` rather than a
/// `CustomPainter`. Kept deliberately simple (a single flat `Stack`, no
/// nested `Transform` wrapping the whole scene) — see CLAUDE.md for why.
class AnimatedSplashScreen extends StatefulWidget {
  const AnimatedSplashScreen({super.key});

  @override
  State<AnimatedSplashScreen> createState() => _AnimatedSplashScreenState();
}

double _clamp01(double v) => v.clamp(0.0, 1.0);

class _AnimatedSplashScreenState extends State<AnimatedSplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final match = Theme.of(context).extension<MatchPalette>() ?? MatchPalette.standard;

    // Scaffold (not bare Material/DecoratedBox) — AppRoot's outer
    // AnimatedSwitcher lays its child out via a Stack whose non-positioned
    // children get loose constraints, so anything else here would
    // shrink-wrap to its content's width instead of filling the screen.
    // Scaffold always claims constraints.biggest regardless.
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: match.backgroundGradient),
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final t = _controller.value;
              return Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: _ShineSweep(t: t, color: match.neonCyan),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _LogoMark(t: t, match: match),
                      const SizedBox(height: 22),
                      _Wordmark(t: t),
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

/// The app icon: fades and scales in with a bouncy overshoot, as if
/// punching into frame, then holds.
class _LogoMark extends StatelessWidget {
  const _LogoMark({required this.t, required this.match});

  final double t;
  final MatchPalette match;

  static const _end = 0.45;

  @override
  Widget build(BuildContext context) {
    final progress = _clamp01(t / _end);
    final scale = lerpDouble(0.3, 1.0, Curves.easeOutBack.transform(progress))!;
    final alpha = _clamp01(t / 0.18);
    if (alpha <= 0) return const SizedBox(width: 116, height: 116);

    return Transform.scale(
      scale: scale,
      child: Container(
        width: 116,
        height: 116,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.1 * alpha),
          border: Border.all(color: Colors.white.withValues(alpha: 0.5 * alpha), width: 1.6),
          boxShadow: [BoxShadow(color: match.neonViolet.withValues(alpha: 0.55 * alpha), blurRadius: 36)],
        ),
        padding: const EdgeInsets.all(20),
        child: Opacity(
          // The one place this screen accepts a real Opacity: fading in a
          // rasterized PNG (unlike the other elements, its "color" isn't
          // ours to bake alpha into) — a single saveLayer for one static
          // image is a different risk profile than several stacked on
          // shape/text layers, and image-only opacity is a well-trodden
          // path (see engineering rule 6).
          opacity: alpha,
          child: Image.asset('assets/images/face-off-icon-1024.png', fit: BoxFit.cover),
        ),
      ),
    );
  }
}

/// "FACE OFF" — fades and slides up into place once the logo has mostly
/// settled.
class _Wordmark extends StatelessWidget {
  const _Wordmark({required this.t});

  final double t;

  static const _start = 0.32;
  static const _end = 0.6;

  @override
  Widget build(BuildContext context) {
    final progress = _clamp01((t - _start) / (_end - _start));
    final eased = Curves.easeOut.transform(progress);

    return Transform.translate(
      offset: Offset(0, (1 - eased) * 16),
      child: Text(
        'FACE OFF',
        style: AppTextStyles.display.copyWith(
          color: Colors.white.withValues(alpha: eased),
          fontSize: 30,
          letterSpacing: 6,
        ),
      ),
    );
  }
}

/// A single diagonal band of light that sweeps across the whole screen once
/// — same translucent-gradient-overlay technique as `ShimmerCard`, not a
/// `CustomPainter`.
class _ShineSweep extends StatelessWidget {
  const _ShineSweep({required this.t, required this.color});

  final double t;
  final Color color;

  static const _start = 0.5;
  static const _end = 0.88;

  @override
  Widget build(BuildContext context) {
    final progress = _clamp01((t - _start) / (_end - _start));
    if (progress <= 0 || progress >= 1) return const SizedBox.shrink();
    final dx = -1.6 + 3.2 * progress;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment(dx - 0.5, -1),
          end: Alignment(dx + 0.5, 1),
          colors: [
            Colors.transparent,
            Colors.white.withValues(alpha: 0.05),
            color.withValues(alpha: 0.22),
            Colors.white.withValues(alpha: 0.05),
            Colors.transparent,
          ],
          stops: const [0.0, 0.4, 0.5, 0.6, 1.0],
        ),
      ),
    );
  }
}
