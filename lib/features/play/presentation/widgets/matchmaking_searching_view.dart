import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../core/widgets/primary_pill_button.dart';

/// Animated waiting state (master prompt Section 7): cancel button always
/// visible, never an indefinite bare spinner.
class MatchmakingSearchingView extends StatefulWidget {
  const MatchmakingSearchingView({super.key, required this.onCancel});

  final VoidCallback onCancel;

  @override
  State<MatchmakingSearchingView> createState() => _MatchmakingSearchingViewState();
}

class _MatchmakingSearchingViewState extends State<MatchmakingSearchingView> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
    ..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pulse = Tween<double>(
      begin: 0.9,
      end: 1.08,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ScaleTransition(
            scale: pulse,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.18),
                border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.4),
              ),
              alignment: Alignment.center,
              child: const AppIcon(HugeIcons.strokeRoundedSearch01, color: Colors.white, size: 56),
            ),
          ),
          const SizedBox(height: 32),
          Text('Finding an opponent…', style: AppTextStyles.headline.copyWith(color: Colors.white)),
          const SizedBox(height: 8),
          Text(
            'Hang tight, this only takes a moment.',
            style: AppTextStyles.body.copyWith(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          SecondaryPillButton(label: 'Cancel', icon: HugeIcons.strokeRoundedCancelCircle, onPressed: widget.onCancel),
        ],
      ),
    );
  }
}
