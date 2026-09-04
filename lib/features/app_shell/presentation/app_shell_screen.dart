import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:showcaseview/showcaseview.dart';

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
/// `addPostFrameCallback`, instead of the old pattern's
/// `WidgetsBinding.instance.addPostFrameCallback` re-registered on *every*
/// `ShowCaseWidget.builder` rebuild (each tab switch, each Friends-badge
/// count change, ...) guarded only by a `_tourTriggerAttempted` flag. That
/// old pattern was the likely cause of a real bug: the tour would flash on
/// screen for a frame and then silently fail — `showcaseview` 3.0.0 had
/// several fixed-in-5.x issues around exactly this shape (races in the
/// async start sequence, null-check crashes on rebuild-during-showcase,
/// missing-target handling). Registering once up front sidesteps that whole
/// class of bug rather than working around it.
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
    return NavVisibilityScope(
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
    );
  }
}
