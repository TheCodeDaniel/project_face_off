import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/lobby_palette.dart';
import 'nav_visibility_controller.dart';

/// Floating pill-shaped bottom nav (master prompt Section 5): auto-hides on
/// scroll-down beyond a small threshold, reappears on scroll-up or after
/// ~600ms idle, never hides while a modal is open on top of it. Rendered
/// above [SafeArea]. Feature screens report scroll deltas via
/// [NavVisibilityScope.of(context)].
class FloatingNavBar extends StatefulWidget {
  const FloatingNavBar({super.key, required this.currentIndex, required this.onTabSelected});

  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  @override
  State<FloatingNavBar> createState() => _FloatingNavBarState();
}

class _FloatingNavBarState extends State<FloatingNavBar> {
  static const _items = [
    (icon: Icons.sports_kabaddi_rounded, label: 'Play'),
    (icon: Icons.people_alt_rounded, label: 'Friends'),
    (icon: Icons.person_rounded, label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<LobbyPalette>() ?? LobbyPalette.standard;
    final visibility = NavVisibilityScope.of(context);

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
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 16, offset: const Offset(0, 6)),
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
                  ),
              ],
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
  });

  final IconData icon;
  final String label;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? accent : Colors.black45;
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 6),
            Text(label, style: AppTextStyles.label.copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}
