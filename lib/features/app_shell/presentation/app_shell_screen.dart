import 'package:flutter/material.dart';

import 'floating_nav_bar.dart';
import 'nav_visibility_controller.dart';

/// Persistent 3-tab shell (Play / Friends / Profile), each a full nested
/// navigator so per-tab back-stacks are preserved (master prompt Section 5).
class AppShellScreen extends StatefulWidget {
  const AppShellScreen({super.key, required this.tabs});

  /// One entry per tab: builder for that tab's root screen. Each is wrapped
  /// in its own [Navigator] below so pushed routes stay scoped to the tab.
  final List<WidgetBuilder> tabs;

  @override
  State<AppShellScreen> createState() => _AppShellScreenState();
}

class _AppShellScreenState extends State<AppShellScreen> {
  int _index = 0;
  final _navigatorKeys = List.generate(3, (_) => GlobalKey<NavigatorState>());
  final _navVisibility = NavVisibilityController();

  void _onTabSelected(int index) {
    if (index == _index) {
      _navigatorKeys[index].currentState?.popUntil((r) => r.isFirst);
      return;
    }
    setState(() => _index = index);
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
