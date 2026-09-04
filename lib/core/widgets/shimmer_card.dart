import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../performance/device_tier.dart';
import '../performance/device_tier_providers.dart';
import '../theme/lobby_palette.dart';

/// Drop-in replacement for a plain `Container(decoration: BoxDecoration(color:
/// palette.cardBackground, ...))` — same cream surface, plus an occasional
/// diagonal silver-white sheen that sweeps across the box, so the lobby's
/// cream cards/tiles/pills don't read as flat and plain. The sweep is rare
/// (every 5-9s, randomized per instance so tiles on the same screen don't
/// glow in lockstep) rather than a constant loop, to stay a subtle detail
/// rather than a distraction.
///
/// Wraps its own [RepaintBoundary] (engineering rule 6 — an independently
/// animating subtree shouldn't repaint its parent). On [DeviceTier.low]
/// (Blueprint Section 6: "visual effects ... scale down automatically on
/// lower tiers"), the sweep is skipped entirely rather than just made
/// subtler — a real screen can have dozens of `ShimmerCard`s on it at once
/// (every stat tile, cosmetic, settings row, ...), each independently
/// scheduling its own `Timer`/`AnimationController`, which is exactly the
/// kind of small-but-multiplied cost a weak device feels first. The card
/// itself (color, border, shadow) is unaffected — only the decorative sweep
/// is gated.
class ShimmerCard extends ConsumerStatefulWidget {
  const ShimmerCard({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
    this.padding,
    this.margin,
    this.color,
    this.boxShadow,
    this.border,
  });

  final Widget child;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final List<BoxShadow>? boxShadow;
  final BoxBorder? border;

  @override
  ConsumerState<ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends ConsumerState<ShimmerCard> with SingleTickerProviderStateMixin {
  static const _sweepDuration = Duration(milliseconds: 1500);
  final _random = Random();

  late final AnimationController _controller = AnimationController(vsync: this, duration: _sweepDuration);
  Timer? _scheduleTimer;
  bool _scheduled = false;

  void _maybeStartScheduling(DeviceTier tier) {
    if (_scheduled || tier == DeviceTier.low) return;
    _scheduled = true;
    _scheduleNextSweep(Duration(milliseconds: 300 + _random.nextInt(3500)));
  }

  void _scheduleNextSweep(Duration delay) {
    // A cancelable Timer, not Future.delayed — the latter can't be aborted
    // in dispose(), which left a pending timer behind after the widget tree
    // was torn down and broke `flutter_test`'s "no pending timers" invariant.
    _scheduleTimer = Timer(delay, () {
      if (!mounted) return;
      _controller.forward(from: 0).whenComplete(() {
        if (!mounted) return;
        _scheduleNextSweep(Duration(milliseconds: 5000 + _random.nextInt(4000)));
      });
    });
  }

  @override
  void dispose() {
    _scheduleTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<LobbyPalette>() ?? LobbyPalette.standard;
    // Deliberately *not* `.valueOrNull ?? DeviceTier.high`: the underlying
    // deviceTierProvider is a FutureProvider, so its first build is always
    // AsyncLoading even when backed by an instantly-resolving cache —
    // defaulting to "high" there and using that single build to decide
    // (`_scheduled = true`) would lock in that optimistic guess permanently
    // and mean the low-tier skip never actually takes effect. Only ever act
    // on a value we've actually resolved. effectiveDeviceTierProvider (see
    // performance_gating_config.dart) is what forces DeviceTier.high outside
    // gated build modes (release, by default) — debug always sees the sweep.
    final tierAsync = ref.watch(effectiveDeviceTierProvider);
    if (tierAsync.hasValue) _maybeStartScheduling(tierAsync.value!);
    return RepaintBoundary(
      child: Container(
        margin: widget.margin,
        decoration: BoxDecoration(
          color: widget.color ?? palette.cardBackground,
          borderRadius: widget.borderRadius,
          border: widget.border,
          boxShadow: widget.boxShadow,
        ),
        child: ClipRRect(
          borderRadius: widget.borderRadius,
          child: Stack(
            children: [
              Padding(padding: widget.padding ?? EdgeInsets.zero, child: widget.child),
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, _) {
                      if (_controller.value == 0) return const SizedBox.shrink();
                      final t = _controller.value;
                      final dx = -1.4 + 2.8 * t;
                      return DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment(dx - 0.6, -1),
                            end: Alignment(dx + 0.6, 1),
                            colors: const [
                              Colors.transparent,
                              Color(0x00E8ECF5),
                              Color(0x99E8ECF5),
                              Color(0x00E8ECF5),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
