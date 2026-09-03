import 'dart:math';
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../theme/app_text_styles.dart';
import '../theme/lobby_palette.dart';
import '../theme/match_palette.dart';
import 'app_icon.dart';
import 'splash_crack_painter.dart';
import 'splash_timeline.dart';

/// App launch splash — two gloves (the app's own brand icon, one per
/// player) trade two probing jabs that bounce off each other, then throw a
/// final clash that cracks the screen open and punches "Face Off" into
/// place through it. A nod to the Gogeta/Broly movie finale, where their
/// clashing fists crack reality itself.
///
/// One [AnimationController] drives every phase — see [SplashTimeline] for
/// the beat-by-beat choreography. Deliberately **no [Opacity] widgets**:
/// every fade is baked directly into a color's alpha instead, because
/// `Opacity` forces an offscreen `saveLayer` per instance, and stacking
/// several of them here (gloves + flash + title, all fading in the same
/// frame) reproducibly triggered an iOS-Simulator/Impeller compositing bug
/// (half the screen rendering black). Baking alpha into colors is both the
/// fix and the cheaper approach. Everything else lives inside a single
/// [RepaintBoundary]/[AnimatedBuilder] (engineering rules 6/7) — the only
/// per-frame work is `Transform`s, color math, and one `CustomPainter`.
class AnimatedSplashScreen extends StatefulWidget {
  const AnimatedSplashScreen({super.key});

  @override
  State<AnimatedSplashScreen> createState() => _AnimatedSplashScreenState();
}

/// Both gloves share this same distance-from-center keyframe track — pull
/// back, lunge to near-touch, bounce off; pull back less, lunge again,
/// bounce off less; pull back for the last time, then go all the way to
/// zero (full contact) and hold through the fade-out.
const _gloveDistanceKeyframes = [
  SplashKeyframe(0, 190),
  SplashKeyframe(SplashTimeline.beat1WindUp, 205, Curves.easeOut),
  SplashKeyframe(SplashTimeline.beat1Lunge, 6, Curves.easeIn),
  SplashKeyframe(SplashTimeline.beat1Recoil, 78, Curves.easeOut),
  SplashKeyframe(SplashTimeline.beat2WindUp, 92, Curves.easeOut),
  SplashKeyframe(SplashTimeline.beat2Lunge, 4, Curves.easeIn),
  SplashKeyframe(SplashTimeline.beat2Recoil, 46, Curves.easeOut),
  SplashKeyframe(SplashTimeline.beat3WindUp, 60, Curves.easeOut),
  SplashKeyframe(SplashTimeline.finalImpact, 0, Curves.easeIn),
  SplashKeyframe(SplashTimeline.gloveFadeEnd, 18, Curves.easeOut),
];

double _clamp01(double v) => v.clamp(0.0, 1.0);

class _AnimatedSplashScreenState extends State<AnimatedSplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  )..forward();

  late final _crackBranches = generateSplashCrackBranches();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lobby = Theme.of(context).extension<LobbyPalette>() ?? LobbyPalette.standard;
    final match = Theme.of(context).extension<MatchPalette>() ?? MatchPalette.standard;

    // Not GradientScaffold — this screen is swapped in/out by AppRoot's own
    // AnimatedSwitcher, which lays its child out with loose constraints (a
    // non-positioned Stack child sizes to its content, not the screen), so a
    // bare Material/DecoratedBox here would shrink-wrap instead of filling
    // the device. Scaffold explicitly takes the biggest size its
    // constraints allow, and gives Text a proper Material ancestor so it
    // doesn't fall back to WidgetsApp's debug underline style.
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: lobby.backgroundGradient),
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final t = _controller.value;
              // The crack sits outside the shake Transform — only the
              // foreground (gloves/flash/title) jolts on impact.
              return Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: SplashCrackPainter(
                        t: t,
                        branches: _crackBranches,
                        glowColor: lobby.coinGold.withValues(alpha: 0.4),
                        coreColor: Colors.white.withValues(alpha: 0.95),
                      ),
                    ),
                  ),
                  Transform.translate(
                    offset: _shakeOffset(t),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        for (final impact in SplashTimeline.impacts)
                          _ImpactFlash(t: t, impactT: impact.t, intensity: impact.intensity, color: lobby.coinGold),
                        _Glove(t: t, isLeft: true, color: match.neonViolet),
                        _Glove(t: t, isLeft: false, color: match.neonCyan),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 130),
                            _PunchInTitle(t: t),
                            const SizedBox(height: 8),
                            Text(
                              "Face your friends. Don't flinch.",
                              style: AppTextStyles.label.copyWith(
                                color: Colors.white.withValues(
                                  alpha:
                                      0.7 *
                                      _clamp01((t - SplashTimeline.taglineStart) / (1 - SplashTimeline.taglineStart)),
                                ),
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// Sums a decaying jitter from each impact whose window `t` currently
  /// falls in — three short shakes escalating to the final, biggest one.
  Offset _shakeOffset(double t) {
    var dx = 0.0;
    var dy = 0.0;
    for (final impact in SplashTimeline.impacts) {
      final progress = ((t - impact.t) / 0.1).clamp(0.0, 1.0);
      if (t < impact.t || progress >= 1) continue;
      final decay = 1 - progress;
      final amplitude = 9 * impact.intensity * decay;
      dx += sin(progress * 40) * amplitude;
      dy += cos(progress * 55) * amplitude * 0.6;
    }
    return Offset(dx, dy);
  }
}

/// One boxing glove — its distance from the clash point follows
/// [_gloveDistanceKeyframes], its rotation is simply proportional to that
/// distance (cocked back when far out, straight at the point of contact,
/// automatically for all three beats with no per-beat branching), and it
/// fades out (alpha baked into its own colors, not an `Opacity` wrapper —
/// see the class doc on [AnimatedSplashScreen]) once the final clash lands.
class _Glove extends StatelessWidget {
  const _Glove({required this.t, required this.isLeft, required this.color});

  final double t;
  final bool isLeft;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final sign = isLeft ? -1.0 : 1.0;
    final distance = keyframedValue(t, _gloveDistanceKeyframes);
    final fadeProgress = _clamp01(
      (t - SplashTimeline.finalImpact) / (SplashTimeline.gloveFadeEnd - SplashTimeline.finalImpact),
    );
    final alpha = 1 - fadeProgress;
    if (alpha <= 0.01) return const SizedBox.shrink();

    final rotation = sign * -0.5 * _clamp01(distance / 160);

    return Transform.translate(
      offset: Offset(sign * distance, 0),
      child: Transform.rotate(
        angle: rotation,
        child: Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.16 * alpha),
            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.5 * alpha), blurRadius: 26)],
          ),
          padding: const EdgeInsets.all(20),
          child: AppIcon(HugeIcons.strokeRoundedBoxingGlove01, color: color.withValues(alpha: alpha), size: 56),
        ),
      ),
    );
  }
}

/// The radial burst at one clash's moment of impact — grows and fades fast,
/// sized/brightened by [intensity] so the final clash flashes bigger than
/// the two probing jabs before it.
class _ImpactFlash extends StatelessWidget {
  const _ImpactFlash({required this.t, required this.impactT, required this.intensity, required this.color});

  final double t;
  final double impactT;
  final double intensity;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final progress = _clamp01((t - impactT) / 0.14);
    if (t < impactT || progress >= 1) return const SizedBox.shrink();
    final scale = lerpDouble(0.2, 1.4 + 1.4 * intensity, Curves.easeOut.transform(progress))!;
    final alpha = (1 - progress) * 0.85 * intensity;

    return Transform.scale(
      scale: scale,
      child: Container(
        width: 90,
        height: 90,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              Colors.white.withValues(alpha: alpha),
              color.withValues(alpha: alpha * 0.6),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }
}

/// "Face Off" punches into place exactly on the final clash — an
/// over-scaled, transparent title snaps down to rest with an
/// overshoot-then-settle curve, as if the impact itself stamped it there.
class _PunchInTitle extends StatelessWidget {
  const _PunchInTitle({required this.t});

  final double t;

  @override
  Widget build(BuildContext context) {
    final progress = _clamp01(
      (t - SplashTimeline.finalImpact) / (SplashTimeline.titlePunchEnd - SplashTimeline.finalImpact),
    );
    final scale = lerpDouble(1.8, 1.0, Curves.easeOutBack.transform(progress))!;
    final alpha = _clamp01(progress / 0.3);

    return Transform.scale(
      scale: scale,
      child: Text(
        'Face Off',
        style: AppTextStyles.display.copyWith(color: Colors.white.withValues(alpha: alpha), fontSize: 38),
      ),
    );
  }
}
