import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../theme/app_text_styles.dart';
import '../widgets/app_icon.dart';

/// Slide-up (not blocking-dialog) offline notice per Blueprint Section 5.
/// Auto-dismisses the instant connectivity + a server health check pass; a
/// manual swipe-down close is still available via the sheet's own drag
/// handle. Call from a listener on [isOnlineProvider] transitioning to false.
///
/// The Lottie illustration asset is not bundled yet — swap the placeholder
/// icon for a Lottie animation once `assets/lottie/offline.json` is added.
class OfflineBottomSheet extends StatelessWidget {
  const OfflineBottomSheet({super.key, required this.onRetry});

  final VoidCallback onRetry;

  static Future<void> show(BuildContext context, {required VoidCallback onRetry}) {
    return showModalBottomSheet(
      context: context,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => OfflineBottomSheet(onRetry: onRetry),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 20),
          const AppIcon(HugeIcons.strokeRoundedWifiOff01, size: 44, color: Colors.black45),
          const SizedBox(height: 12),
          Text("You're offline", style: AppTextStyles.headline.copyWith(color: Colors.black87)),
          const SizedBox(height: 4),
          Text(
            'Check your connection — we\'ll reconnect automatically.',
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(color: Colors.black54),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ),
        ],
      ),
    );
  }
}
