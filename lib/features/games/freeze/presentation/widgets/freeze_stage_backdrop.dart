import 'package:flutter/material.dart';

import '../../../../../core/theme/match_palette.dart';
import '../../../../../core/widgets/layered_depth_scene.dart';

/// Freeze's stage — the same shared [LayeredDepthScene] approach as Bow &
/// Draw's range (game/UI/backend guideline Section 1), just a different
/// silhouette: icy pillars and a frost-sparkle sky instead of hills and
/// stars, reinforcing the "hold still" register with a cold, still-feeling
/// space rather than an outdoor range.
class FreezeStageBackdrop extends StatelessWidget {
  const FreezeStageBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<MatchPalette>() ?? MatchPalette.standard;

    return LayeredDepthScene(
      layers: [
        DepthLayer(
          parallax: 5,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [palette.backgroundNavy, palette.backgroundIndigo],
              ),
            ),
          ),
        ),
        DepthLayer(parallax: 5, child: CustomPaint(painter: _FrostSparklePainter())),
        DepthLayer(
          parallax: 16,
          scale: 1.06,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: FractionallySizedBox(
              heightFactor: 0.4,
              widthFactor: 1,
              child: CustomPaint(painter: _IcePillarsPainter(color: palette.neonCyan.withValues(alpha: 0.18))),
            ),
          ),
        ),
        DepthLayer(
          parallax: 28,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: FractionallySizedBox(
              heightFactor: 0.2,
              widthFactor: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [palette.backgroundIndigo.withValues(alpha: 0), palette.backgroundIndigo],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FrostSparklePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.55);
    const positions = [
      Offset(0.1, 0.15),
      Offset(0.28, 0.3),
      Offset(0.5, 0.1),
      Offset(0.66, 0.24),
      Offset(0.8, 0.12),
      Offset(0.92, 0.28),
      Offset(0.35, 0.06),
      Offset(0.05, 0.32),
    ];
    for (final p in positions) {
      canvas.drawCircle(Offset(p.dx * size.width, p.dy * size.height), 1.4, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _FrostSparklePainter oldDelegate) => false;
}

class _IcePillarsPainter extends CustomPainter {
  _IcePillarsPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final widths = [0.1, 0.14, 0.09, 0.16, 0.11];
    final heights = [0.5, 0.85, 0.35, 0.7, 0.45];
    var x = 0.0;
    for (var i = 0; i < widths.length; i++) {
      final w = widths[i] * size.width;
      final h = heights[i] * size.height;
      final rect = Rect.fromLTWH(x, size.height - h, w, h);
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(6)), paint);
      x += w + size.width * 0.02;
    }
  }

  @override
  bool shouldRepaint(covariant _IcePillarsPainter oldDelegate) => oldDelegate.color != color;
}
