import 'dart:async';

import 'package:flutter/material.dart';

/// Drives [FloatingNavBar]'s show/hide animation from scroll notifications
/// (master prompt Section 5): hides past a small downward-scroll threshold,
/// reappears on scroll-up or after ~600ms idle. A modal/bottom-sheet can call
/// [lock]/[unlock] to force it visible and ignore scroll while open on top.
class NavVisibilityController extends ChangeNotifier {
  static const _hideThreshold = 12.0;
  static const _idleDelay = Duration(milliseconds: 600);

  bool _visible = true;
  bool _locked = false;
  Timer? _idleTimer;

  bool get visible => _visible || _locked;

  void lock() {
    _locked = true;
    notifyListeners();
  }

  void unlock() {
    _locked = false;
    notifyListeners();
  }

  void onScrollDelta(double delta) {
    if (_locked) return;
    _idleTimer?.cancel();
    _idleTimer = Timer(_idleDelay, _showAfterIdle);

    if (delta > _hideThreshold) {
      _setVisible(false);
    } else if (delta < -_hideThreshold) {
      _setVisible(true);
    }
  }

  void _showAfterIdle() => _setVisible(true);

  void _setVisible(bool value) {
    if (_visible == value) return;
    _visible = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _idleTimer?.cancel();
    super.dispose();
  }
}

/// Provides the shell-level [NavVisibilityController] down to tab screens so
/// their scrollables can report deltas without prop-drilling.
class NavVisibilityScope extends InheritedNotifier<NavVisibilityController> {
  const NavVisibilityScope({super.key, required NavVisibilityController controller, required super.child})
    : super(notifier: controller);

  static NavVisibilityController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<NavVisibilityScope>();
    assert(scope != null, 'NavVisibilityScope not found in context');
    return scope!.notifier!;
  }
}
