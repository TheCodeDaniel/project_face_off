import 'package:flutter/widgets.dart';

/// Shared [GlobalKey]s for the post-sign-in product tour (master prompt
/// Section 6): Play tab's quick-match button, Friends tab's entry point, and
/// Profile tab's subscription entry point. Lives in `core/` because the
/// `app_shell` and `play` features both need to attach `Showcase` widgets to
/// the same keys — a feature must never reach into another feature's
/// internals, so this is the shared contract they both depend on instead.
abstract final class TourKeys {
  static final quickMatch = GlobalKey();
  static final friendsNav = GlobalKey();
  static final profileNav = GlobalKey();

  static List<GlobalKey> get all => [quickMatch, friendsNav, profileNav];
}
