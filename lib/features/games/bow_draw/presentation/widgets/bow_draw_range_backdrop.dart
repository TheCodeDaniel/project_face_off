import 'package:flutter/material.dart';

import '../../../../../core/theme/match_palette.dart';
import '../../../../../core/widgets/layered_depth_scene.dart';

/// Bow & Draw's first-person range — three flat layers in [LayeredDepthScene]
/// (sky, hills, ground) built entirely from gradients/shapes, no raster
/// assets, matching this app's existing icon+gradient visual language
/// (game/UI/backend guideline Section 1: layered depth via `Transform`, not
/// real 3D).
class BowDrawRangeBackdrop extends StatelessWidget {
  const BowDrawRangeBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<MatchPalette>() ?? MatchPalette.standard;

    return LayeredDepthScene(
      layers: [
        DepthLayer(
          parallax: 6,
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
        DepthLayer(parallax: 6, child: CustomPaint(painter: _StarsPainter())),
        DepthLayer(
          parallax: 18,
          scale: 1.08,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: FractionallySizedBox(
              heightFactor: 0.42,
              widthFactor: 1,
              child: CustomPaint(painter: _HillsPainter(color: palette.neonViolet.withValues(alpha: 0.22))),
            ),
          ),
        ),
        DepthLayer(
          parallax: 30,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: FractionallySizedBox(
              heightFactor: 0.22,
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

class _StarsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.5);
    const positions = [
      Offset(0.08, 0.12),
      Offset(0.22, 0.28),
      Offset(0.4, 0.08),
      Offset(0.58, 0.22),
      Offset(0.72, 0.1),
      Offset(0.86, 0.3),
      Offset(0.94, 0.15),
      Offset(0.15, 0.35),
    ];
    for (final p in positions) {
      canvas.drawCircle(Offset(p.dx * size.width, p.dy * size.height), 1.6, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _StarsPainter oldDelegate) => false;
}

class _HillsPainter extends CustomPainter {
  _HillsPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, size.height * 0.6)
      ..quadraticBezierTo(size.width * 0.22, size.height * 0.15, size.width * 0.48, size.height * 0.5)
      ..quadraticBezierTo(size.width * 0.7, size.height * 0.75, size.width, size.height * 0.35)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _HillsPainter oldDelegate) => oldDelegate.color != color;
}
