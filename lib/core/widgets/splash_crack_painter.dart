import 'dart:math';

import 'package:flutter/rendering.dart';

import 'splash_timeline.dart';

/// One jagged fracture line, in polar coordinates relative to the impact
/// point — `dx` is angle (radians), `dy` is radius as a fraction of the
/// painter's `maxRadius`. Generated once from a fixed seed (see
/// [generateSplashCrackBranches]) rather than per frame, so the shatter
/// pattern is stable across rebuilds instead of re-randomizing every paint.
class SplashCrackBranch {
  SplashCrackBranch(double baseAngle, Random random) : points = _generatePoints(baseAngle, random);

  final List<Offset> points;

  static List<Offset> _generatePoints(double baseAngle, Random random) {
    const segments = 4;
    var angle = baseAngle;
    var radius = 0.05;
    final points = [Offset(angle, radius)];
    for (var i = 0; i < segments; i++) {
      angle += (random.nextDouble() - 0.5) * 0.3;
      radius += 0.22 + random.nextDouble() * 0.14;
      points.add(Offset(angle, radius));
    }
    return points;
  }
}

/// A fixed shatter pattern radiating from the impact point — evenly spaced
/// base angles with a fixed-seed jitter so it looks organic without being
/// different on every rebuild.
List<SplashCrackBranch> generateSplashCrackBranches({int count = 9}) {
  final random = Random(2024);
  return [for (var i = 0; i < count; i++) SplashCrackBranch((2 * pi / count) * i + random.nextDouble() * 0.3, random)];
}

/// Draws [branches] growing outward from the impact point as `t` advances —
/// "reality cracking open" off the gloves' final clash. Each branch reveals
/// on its own staggered slice of `t` (see `_startT`/`_staggerPerBranch`) so
/// the fractures spread outward one after another rather than all at once.
/// Two passes per branch (a blurred glow stroke, then a thin bright core)
/// sell the light-bleeding-through-the-crack look cheaply — no shaders, just
/// two `Path` strokes.
class SplashCrackPainter extends CustomPainter {
  SplashCrackPainter({required this.t, required this.branches, required this.glowColor, required this.coreColor});

  final double t;
  final List<SplashCrackBranch> branches;
  final Color glowColor;
  final Color coreColor;

  static const _startT = SplashTimeline.finalImpact;
  static const _staggerPerBranch = 0.014;
  static const _branchDuration = 0.16;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final maxRadius = size.longestSide * 0.75;

    // Layered strokes (wide+faint down to thin+bright) instead of a
    // MaskFilter.blur "glow" — cheaper, and it avoids relying on blur
    // compositing at all for this decorative pass.
    final outerGlow = Paint()
      ..color = glowColor.withValues(alpha: glowColor.a * 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    final innerGlow = Paint()
      ..color = glowColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    final core = Paint()
      ..color = coreColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < branches.length; i++) {
      final localT = ((t - (_startT + i * _staggerPerBranch)) / _branchDuration).clamp(0.0, 1.0);
      if (localT <= 0) continue;
      final path = _buildPath(branches[i], center, maxRadius, localT);
      canvas.drawPath(path, outerGlow);
      canvas.drawPath(path, innerGlow);
      canvas.drawPath(path, core);
    }
  }

  Path _buildPath(SplashCrackBranch branch, Offset center, double maxRadius, double localT) {
    Offset toCanvas(Offset polar) => center + Offset(cos(polar.dx), sin(polar.dx)) * polar.dy * maxRadius;

    final points = branch.points;
    final progress = localT * (points.length - 1);
    final fullSegments = progress.floor();

    final path = Path()..moveTo(toCanvas(points.first).dx, toCanvas(points.first).dy);
    for (var i = 1; i <= fullSegments && i < points.length; i++) {
      final p = toCanvas(points[i]);
      path.lineTo(p.dx, p.dy);
    }
    if (fullSegments < points.length - 1) {
      final segT = progress - fullSegments;
      final from = points[fullSegments];
      final to = points[fullSegments + 1];
      final lerped = Offset(from.dx + (to.dx - from.dx) * segT, from.dy + (to.dy - from.dy) * segT);
      final p = toCanvas(lerped);
      path.lineTo(p.dx, p.dy);
    }
    return path;
  }

  @override
  bool shouldRepaint(covariant SplashCrackPainter oldDelegate) => oldDelegate.t != t;
}
