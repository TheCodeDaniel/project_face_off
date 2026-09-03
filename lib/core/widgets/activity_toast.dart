import 'package:flutter/material.dart';

import '../theme/app_text_styles.dart';

/// Small, non-blocking event announcement (Blueprint Section 1, voxel mini-golf
/// reference): "Opponent raised an eyebrow — dodged!". Call
/// [ActivityToast.show] with the current [BuildContext]; it self-dismisses.
/// Demo:
/// ```dart
/// ActivityToast.show(context, message: 'Opponent cracked first!');
/// ```
class ActivityToast {
  ActivityToast._();

  static void show(
    BuildContext context, {
    required String message,
    IconData icon = Icons.bolt_rounded,
    Duration duration = const Duration(seconds: 2),
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) =>
          _ToastWidget(message: message, icon: icon, onDone: () => entry.remove(), visibleDuration: duration),
    );
    overlay.insert(entry);
  }
}

class _ToastWidget extends StatefulWidget {
  const _ToastWidget({required this.message, required this.icon, required this.onDone, required this.visibleDuration});

  final String message;
  final IconData icon;
  final VoidCallback onDone;
  final Duration visibleDuration;

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 250));
    _controller.forward();
    Future.delayed(widget.visibleDuration, () async {
      if (!mounted) return;
      await _controller.reverse();
      widget.onDone();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 12,
      left: 16,
      right: 16,
      child: FadeTransition(
        opacity: _controller,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -0.3),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic)),
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(14)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(widget.icon, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(widget.message, style: AppTextStyles.label.copyWith(color: Colors.white)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
