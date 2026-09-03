import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:showcaseview/showcaseview.dart';

import '../../../core/onboarding_tour/tour_keys.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/lobby_palette.dart';
import '../../../core/widgets/app_icon.dart';
import '../../friends/presentation/friends_providers.dart';
import 'nav_visibility_controller.dart';

/// Floating glass-pill bottom nav (master prompt Section 5): frosted/blurred
/// translucent background rather than a flat card, icon-first items where
/// only the selected tab grows a label — keeps the bar compact and lets the
/// icon set (hugeicons) carry the read rather than three text labels
/// competing with the gradient behind it. Auto-hides on scroll-down past a
/// small threshold, reappears on scroll-up or after ~600ms idle, never hides
/// while a modal is open on top of it. Also carries the Friends tab's
/// incoming-request badge count (master prompt Section 9).
class FloatingNavBar extends ConsumerStatefulWidget {
  const FloatingNavBar({super.key, required this.currentIndex, required this.onTabSelected});

  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  @override
  ConsumerState<FloatingNavBar> createState() => _FloatingNavBarState();
}

class _FloatingNavBarState extends ConsumerState<FloatingNavBar> {
  static const _items = [
    (icon: HugeIcons.strokeRoundedBoxingGlove01, label: 'Play'),
    (icon: HugeIcons.strokeRoundedUserGroup, label: 'Friends'),
    (icon: HugeIcons.strokeRoundedUserCircle02, label: 'Profile'),
  ];

  /// Product-tour targets (master prompt Section 6) — Friends and Profile
  /// entry points. `null` for Play since its tour target is the Quick Match
  /// button on that tab's own content, not the nav item.
  List<GlobalKey?> get _tourKeys => [null, TourKeys.friendsNav, TourKeys.profileNav];

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<LobbyPalette>() ?? LobbyPalette.standard;
    final visibility = NavVisibilityScope.of(context);
    final friendsBadgeCount = ref.watch(incomingRequestsCountProvider);

    return SafeArea(
      child: AnimatedBuilder(
        animation: visibility,
        builder: (context, child) {
          return AnimatedSlide(
            duration: const Duration(milliseconds: 200),
            offset: visibility.visible ? Offset.zero : const Offset(0, 0.4),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: visibility.visible ? 1 : 0,
              child: child,
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.2),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 20, offset: const Offset(0, 8)),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < _items.length; i++)
                      _NavItem(
                        icon: _items[i].icon,
                        label: _items[i].label,
                        selected: widget.currentIndex == i,
                        accent: palette.gradientMid,
                        onTap: () => widget.onTabSelected(i),
                        showcaseKey: _tourKeys[i],
                        showcaseTitle: _items[i].label,
                        badgeCount: i == 1 ? friendsBadgeCount : 0,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.accent,
    required this.onTap,
    this.showcaseKey,
    this.showcaseTitle,
    this.badgeCount = 0,
  });

  final List<List<dynamic>> icon;
  final String label;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;
  final GlobalKey? showcaseKey;
  final String? showcaseTitle;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    final button = InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(horizontal: selected ? 16 : 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? accent : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AppIcon(icon, color: selected ? Colors.white : Colors.black54, size: 22),
                if (badgeCount > 0) Positioned(right: -6, top: -4, child: _NavBadge(count: badgeCount)),
              ],
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              child: selected
                  ? Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Text(label, style: AppTextStyles.label.copyWith(color: Colors.white)),
                    )
                  : const SizedBox(width: 0, height: 0),
            ),
          ],
        ),
      ),
    );

    final key = showcaseKey;
    if (key == null) return button;
    return Showcase(
      key: key,
      title: showcaseTitle,
      description: 'Check out $showcaseTitle',
      targetShapeBorder: const CircleBorder(),
      child: button,
    );
  }
}

class _NavBadge extends StatelessWidget {
  const _NavBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      constraints: const BoxConstraints(minWidth: 16),
      decoration: const BoxDecoration(color: Color(0xFFFF4D6D), shape: BoxShape.circle),
      child: Text(
        count > 9 ? '9+' : '$count',
        textAlign: TextAlign.center,
        style: AppTextStyles.label.copyWith(color: Colors.white, fontSize: 10),
      ),
    );
  }
}
