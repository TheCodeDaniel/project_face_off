import 'package:flutter/material.dart';

/// First-person bow-and-arrow rig, bottom-of-screen. The string's pull-back
/// distance is driven directly by [power] (0.0-1.0) — this is, per the
/// game/UI/backend guideline, "the single most important visual feedback
/// loop" in Bow & Draw: no `AnimationController` smoothing sits between a
/// real draw gesture and what renders here, so it tracks the live gesture
/// value frame-for-frame the same way the dev drag harness already does.
class BowRig extends StatelessWidget {
  const BowRig({super.key, required this.power, required this.accentColor});

  final double power;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        height: 200,
        width: double.infinity,
        child: CustomPaint(
          painter: _BowPainter(power: power.clamp(0.0, 1.0), color: accentColor),
        ),
      ),
    );
  }
}

class _BowPainter extends CustomPainter {
  _BowPainter({required this.power, required this.color});

  final double power;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final bowX = size.width * 0.5 + 60;
    final bowTop = Offset(bowX, size.height * 0.06);
    final bowBottom = Offset(bowX, size.height * 0.94);
    final bowCenter = Offset(bowX - 46, size.height * 0.5);

    final bowPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    final bowPath = Path()
      ..moveTo(bowTop.dx, bowTop.dy)
      ..quadraticBezierTo(bowCenter.dx, bowCenter.dy, bowBottom.dx, bowBottom.dy);
    canvas.drawPath(bowPath, bowPaint);

    final pullBack = 110 * power;
    final nock = Offset(bowX + pullBack, size.height * 0.5);
    final stringPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..strokeWidth = 2;
    canvas.drawLine(bowTop, nock, stringPaint);
    canvas.drawLine(bowBottom, nock, stringPaint);

    if (power > 0.03) {
      final arrowPaint = Paint()
        ..color = color
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round;
      final tip = Offset(nock.dx + 150, nock.dy);
      canvas.drawLine(nock, tip, arrowPaint);

      final headPaint = Paint()..color = color;
      final headPath = Path()
        ..moveTo(tip.dx, tip.dy)
        ..lineTo(tip.dx - 14, tip.dy - 7)
        ..lineTo(tip.dx - 14, tip.dy + 7)
        ..close();
      canvas.drawPath(headPath, headPaint);

      final glowPaint = Paint()
        ..color = color.withValues(alpha: 0.22 * power)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22);
      canvas.drawCircle(nock, 26 + 18 * power, glowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _BowPainter oldDelegate) => oldDelegate.power != power || oldDelegate.color != color;
}
