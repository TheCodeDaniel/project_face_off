import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:showcaseview/showcaseview.dart';

import '../../../core/connectivity/connectivity_gate.dart';
import '../../../core/onboarding_tour/tour_keys.dart';
import '../../../core/onboarding_tour/tour_style.dart';
import '../../onboarding/presentation/onboarding_providers.dart';
import 'floating_nav_bar.dart';
import 'nav_visibility_controller.dart';

/// Persistent 3-tab shell (Play / Friends / Profile), each a full nested
/// navigator so per-tab back-stacks are preserved (master prompt Section 5).
/// Also owns the [ShowcaseView] registration for the post-sign-in product
/// tour (Section 6) — it's the natural owner since the tour's three targets
/// (Quick Match button, Friends nav, Profile nav) all live inside the shell.
///
/// Migrated off the (now-deprecated) context-dependent `ShowCaseWidget` onto
/// `ShowcaseView.register`/`.get()`: registering once in `initState` and
/// starting the tour once via a single `initState`-scoped
/// `addPostFrameCallback`, instead of the old pattern re-registering its
/// trigger on *every* `ShowCaseWidget.builder` rebuild.
///
/// **On the "tour flashes for a frame then vanishes" bug**: this class was
/// not the actual cause, despite being the obvious suspect. Instrumenting
/// `_maybeStartTour` (temporarily) proved `initState` was running *twice*
/// on a single launch — i.e. `AppShellScreen`'s whole `State` was being
/// torn down and recreated a beat after the tour had already started,
/// which orphaned the first `ShowcaseView` registration and silently
/// dropped its overlay. The real bug was one level up, in `AppRoot`'s
/// `AnimatedSwitcher.layoutBuilder` (`lib/main.dart`) — its
/// `Positioned.fill` wrappers had no `key`, so once the splash→shell
/// crossfade finished and the Stack's children list shrank back to one
/// item, positional reconciliation mismatched the slot and rebuilt this
/// widget from scratch instead of reusing the already-mounted element.
/// See the comment on that `layoutBuilder` for the full explanation.
/// `_maybeStartTour` below still polls `ShowcaseView.isTargetRendered`
/// before calling `startShowCase`, which is a real (if secondary) fix for
/// a genuine race against the Play tab's nested `Navigator`.
class AppShellScreen extends ConsumerStatefulWidget {
  const AppShellScreen({super.key, required this.tabs});

  /// One entry per tab: builder for that tab's root screen. Each is wrapped
  /// in its own [Navigator] below so pushed routes stay scoped to the tab.
  final List<WidgetBuilder> tabs;

  @override
  ConsumerState<AppShellScreen> createState() => _AppShellScreenState();
}

class _AppShellScreenState extends ConsumerState<AppShellScreen> {
  int _index = 0;
  final _navigatorKeys = List.generate(3, (_) => GlobalKey<NavigatorState>());
  final _navVisibility = NavVisibilityController();
  late final ShowcaseView _showcaseView;

  void _onTabSelected(int index) {
    if (index == _index) {
      _navigatorKeys[index].currentState?.popUntil((r) => r.isFirst);
      return;
    }
    setState(() => _index = index);
  }

  Future<void> _maybeStartTour() async {
    final hasSeenTour = await ref.read(onboardingRepositoryProvider).hasSeenTour();
    if (hasSeenTour || !mounted) return;

    // The first frame after AppShellScreen mounts is not always enough —
    // its first target (Quick Match) lives inside the Play tab's own
    // nested Navigator, whose route content can register its Showcase
    // controller with ShowcaseService a beat later than AppShellScreen's
    // own build. Poll isTargetRendered (the 5.x replacement for the old
    // key.currentContext check) instead of guessing a fixed delay.
    var attempts = 0;
    while (!_showcaseView.isTargetRendered(TourKeys.quickMatch) && attempts < 20) {
      if (!mounted) return;
      await Future<void>.delayed(const Duration(milliseconds: 50));
      attempts++;
    }
    if (!mounted) return;

    _showcaseView.startShowCase(TourKeys.all);
    await ref.read(onboardingRepositoryProvider).markTourSeen();
  }

  @override
  void initState() {
    super.initState();
    _showcaseView = ShowcaseView.register(
      blurValue: 1.5,
      disableMovingAnimation: false,
      enableAutoScroll: true,
      globalTooltipActions: tourActions(),
      globalTooltipActionConfig: const TooltipActionConfig(position: TooltipActionPosition.outside, actionGap: 8),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeStartTour());
  }

  @override
  void dispose() {
    _showcaseView.unregister();
    _navVisibility.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ConnectivityGate(
      child: NavVisibilityScope(
        controller: _navVisibility,
        child: Scaffold(
          body: Stack(
            children: [
              for (var i = 0; i < widget.tabs.length; i++)
                Offstage(
                  offstage: _index != i,
                  child: Navigator(
                    key: _navigatorKeys[i],
                    onGenerateRoute: (settings) => MaterialPageRoute(builder: widget.tabs[i]),
                  ),
                ),
              Align(
                alignment: Alignment.bottomCenter,
                child: FloatingNavBar(currentIndex: _index, onTabSelected: _onTabSelected),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
