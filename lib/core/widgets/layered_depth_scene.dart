import 'package:flutter/material.dart';

/// One flat layer in a [LayeredDepthScene] — HD-2D-style layered depth via
/// plain `Transform`, not real 3D (game/UI/backend guideline Section 1:
/// "flat sprites in layered depth via Transform/Matrix4 ... NOT real 3D,
/// dynamic lighting, or particle-heavy effects"). Shared between Bow &
/// Draw's range and Freeze's stage rather than each game building its own
/// depth-layering plumbing.
@immutable
class DepthLayer {
  const DepthLayer({required this.child, this.parallax = 0, this.scale = 1});

  final Widget child;

  /// How far this layer drifts opposite a slow, continuous simulated camera
  /// sway — 0 for a layer that should feel fixed/near, higher for distant
  /// layers that should feel further away and drift less in the frame.
  final double parallax;

  /// Static scale — nearer layers slightly larger, farther layers slightly
  /// smaller, reinforcing depth order without real perspective math.
  final double scale;
}

/// A `Stack` of [DepthLayer]s driven by one shared, slow, continuous
/// horizontal sway — the entire scene is one independently-animating
/// subtree, wrapped in its own [RepaintBoundary] per engineering rule 6 so
/// its repaint never forces static HUD siblings (score header, HUD capsule)
/// to repaint too.
class LayeredDepthScene extends StatefulWidget {
  const LayeredDepthScene({super.key, required this.layers});

  final List<DepthLayer> layers;

  @override
  State<LayeredDepthScene> createState() => _LayeredDepthSceneState();
}

class _LayeredDepthSceneState extends State<LayeredDepthScene> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 16))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final sway = Curves.easeInOut.transform(_controller.value) * 2 - 1; // -1..1
          return Stack(
            fit: StackFit.expand,
            children: widget.layers
                .map(
                  (layer) => Transform.translate(
                    offset: Offset(sway * layer.parallax, 0),
                    child: Transform.scale(scale: layer.scale, child: layer.child),
                  ),
                )
                .toList(growable: false),
          );
        },
      ),
    );
  }
}
