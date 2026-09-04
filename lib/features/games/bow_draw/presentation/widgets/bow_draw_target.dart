import 'package:flutter/material.dart';

/// Decorative target visual — deliberately never labels the exact power a
/// shot must land near (that stays hidden, same "don't reveal the precise
/// target" instinct as Face Off's cue). [armed] pulses the rings and swaps
/// in the accent color once the shot window is actually open; otherwise it
/// sits dim, waiting.
class BowDrawTarget extends StatefulWidget {
  const BowDrawTarget({super.key, required this.armed, required this.accentColor});

  final bool armed;
  final Color accentColor;

  @override
  State<BowDrawTarget> createState() => _BowDrawTargetState();
}

class _BowDrawTargetState extends State<BowDrawTarget> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dimColor = Colors.white.withValues(alpha: 0.35);
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final pulse = widget.armed ? (0.85 + 0.15 * _controller.value) : 1.0;
          final ringColor = widget.armed ? widget.accentColor : dimColor;
          return Transform.scale(
            scale: pulse,
            child: SizedBox(
              width: 96,
              height: 96,
              child: CustomPaint(painter: _TargetPainter(color: ringColor)),
            ),
          );
        },
      ),
    );
  }
}

class _TargetPainter extends CustomPainter {
  _TargetPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final maxRadius = size.shortestSide / 2;
    for (var i = 0; i < 3; i++) {
      final radius = maxRadius * (1 - i * 0.3);
      final paint = Paint()
        ..color = color.withValues(alpha: 0.9 - i * 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4;
      canvas.drawCircle(center, radius, paint);
    }
    canvas.drawCircle(center, maxRadius * 0.12, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _TargetPainter oldDelegate) => oldDelegate.color != color;
}
