import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:showcaseview/showcaseview.dart';

import '../../../core/onboarding_tour/tour_keys.dart';
import '../../onboarding/presentation/onboarding_providers.dart';
import 'floating_nav_bar.dart';
import 'nav_visibility_controller.dart';

/// Persistent 3-tab shell (Play / Friends / Profile), each a full nested
/// navigator so per-tab back-stacks are preserved (master prompt Section 5).
/// Also hosts the [ShowCaseWidget] for the post-sign-in product tour
/// (Section 6) — it's the natural ancestor since the tour's three targets
/// (Quick Match button, Friends nav, Profile nav) all live inside the shell.
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
  bool _tourTriggerAttempted = false;

  void _onTabSelected(int index) {
    if (index == _index) {
      _navigatorKeys[index].currentState?.popUntil((r) => r.isFirst);
      return;
    }
    setState(() => _index = index);
  }

  Future<void> _maybeStartTour(BuildContext showcaseContext) async {
    if (_tourTriggerAttempted) return;
    _tourTriggerAttempted = true;
    final hasSeenTour = await ref.read(onboardingRepositoryProvider).hasSeenTour();
    if (hasSeenTour || !showcaseContext.mounted) return;
    ShowCaseWidget.of(showcaseContext).startShowCase(TourKeys.all);
    await ref.read(onboardingRepositoryProvider).markTourSeen();
  }

  @override
  void dispose() {
    _navVisibility.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NavVisibilityScope(
      controller: _navVisibility,
      child: ShowCaseWidget(
        builder: (showcaseContext) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _maybeStartTour(showcaseContext));
          return Scaffold(
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
          );
        },
      ),
    );
  }
}
