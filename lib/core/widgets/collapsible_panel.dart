import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../theme/app_text_styles.dart';
import 'app_icon.dart';

/// Caret-expandable bottom panel with internal toggles (Blueprint Section 1,
/// voxel mini-golf scorecard reference). Used for the in-match score panel.
/// Demo:
/// ```dart
/// CollapsiblePanel(title: 'Scorecard', child: Text('...'))
/// ```
class CollapsiblePanel extends StatefulWidget {
  const CollapsiblePanel({
    super.key,
    required this.title,
    required this.child,
    this.initiallyExpanded = true,
    this.backgroundColor,
    this.foregroundColor = Colors.white,
  });

  final String title;
  final Widget child;
  final bool initiallyExpanded;
  final Color? backgroundColor;
  final Color foregroundColor;

  @override
  State<CollapsiblePanel> createState() => _CollapsiblePanelState();
}

class _CollapsiblePanelState extends State<CollapsiblePanel> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final bg = widget.backgroundColor ?? Colors.black.withValues(alpha: 0.55);
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        color: bg,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Row(
                children: [
                  Expanded(
                    child: Text(widget.title, style: AppTextStyles.label.copyWith(color: widget.foregroundColor)),
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: AppIcon(HugeIcons.strokeRoundedArrowDown01, color: widget.foregroundColor, size: 18),
                  ),
                ],
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              child: _expanded
                  ? Padding(padding: const EdgeInsets.only(top: 8), child: widget.child)
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
