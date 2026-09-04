import 'package:flutter/material.dart';

import '../theme/app_text_styles.dart';

/// Imperative handle for spawning a [FloatingLabelLayer]'s labels —
/// decouples "something happened at this point" call sites (a hit landing,
/// a bust) from the `Stack` that actually renders them, the same shape as
/// `ActivityToast.show` but scoped to one game screen's coordinate space
/// instead of a full-screen `Overlay`.
class FloatingLabelController {
  void Function({required String text, required Offset position, required Color color})? _spawn;

  void spawn({required String text, required Offset position, Color color = Colors.white}) {
    _spawn?.call(text: text, position: position, color: color);
  }
}

/// World-space floating text — spawns at a point and drifts upward while
/// fading, similar energy to `ActivityToast` but transient and positioned
/// wherever the triggering event happened rather than a fixed screen edge
/// (game/UI/backend guideline Section 1). Shared across all three games'
/// visual layers rather than each building its own transient-label plumbing.
class FloatingLabelLayer extends StatefulWidget {
  const FloatingLabelLayer({super.key, required this.controller});

  final FloatingLabelController controller;

  @override
  State<FloatingLabelLayer> createState() => _FloatingLabelLayerState();
}

class _FloatingLabelLayerState extends State<FloatingLabelLayer> {
  final _labels = <_ActiveLabel>[];
  var _nextId = 0;

  @override
  void initState() {
    super.initState();
    widget.controller._spawn = _spawn;
  }

  void _spawn({required String text, required Offset position, required Color color}) {
    final id = _nextId++;
    setState(() => _labels.add(_ActiveLabel(id: id, text: text, position: position, color: color)));
  }

  void _remove(int id) {
    if (!mounted) return;
    setState(() => _labels.removeWhere((label) => label.id == id));
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: _labels
            .map((label) => _FloatingLabel(key: ValueKey(label.id), label: label, onDone: () => _remove(label.id)))
            .toList(growable: false),
      ),
    );
  }
}

class _ActiveLabel {
  const _ActiveLabel({required this.id, required this.text, required this.position, required this.color});

  final int id;
  final String text;
  final Offset position;
  final Color color;
}

class _FloatingLabel extends StatefulWidget {
  const _FloatingLabel({super.key, required this.label, required this.onDone});

  final _ActiveLabel label;
  final VoidCallback onDone;

  @override
  State<_FloatingLabel> createState() => _FloatingLabelState();
}

class _FloatingLabelState extends State<_FloatingLabel> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
    _controller.forward().whenComplete(widget.onDone);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Positioned must be the widget whose render-tree child ends up as
    // Stack's direct child — wrapping it in RepaintBoundary/AnimatedBuilder
    // instead of the other way around throws "Incorrect use of
    // ParentDataWidget" at runtime, since the StackParentData Positioned
    // sets would land on Text's render object while RepaintBoundary's render
    // object is what Stack actually sees as its child. AnimatedBuilder has
    // no render object of its own, so it's transparent here and safe to
    // return Positioned directly from its builder; RepaintBoundary moves
    // inside Positioned's child instead.
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        final dy = -70 * Curves.easeOutCubic.transform(t);
        // Fade baked directly into the text color's alpha rather than a
        // bare Opacity widget — see CLAUDE.md's Opacity-audit lesson on
        // AnimatedSplashScreen/DuelVsTransition for why, now applied here
        // too since this sits alongside other independently-animating
        // siblings (bow rig, background sway) in the same frame.
        final opacity = t < 0.65 ? 1.0 : (1 - (t - 0.65) / 0.35).clamp(0.0, 1.0);
        return Positioned(
          left: widget.label.position.dx,
          top: widget.label.position.dy + dy,
          child: RepaintBoundary(
            child: Text(
              widget.label.text,
              style: AppTextStyles.headline.copyWith(
                color: widget.label.color.withValues(alpha: opacity),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        );
      },
    );
  }
}
