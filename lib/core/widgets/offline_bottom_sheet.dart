import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import '../connectivity/connectivity_providers.dart';
import '../theme/app_text_styles.dart';
import '../theme/lobby_palette.dart';
import 'app_icon.dart';
import 'primary_pill_button.dart';

/// The app-wide "you're offline" sheet (master prompt Section 12, Blueprint
/// Section 5): slides up (not a blocking dialog), simple illustration,
/// "You're offline" message, "Retry" button. [ConnectivityGate] owns
/// showing/auto-dismissing this — this widget only renders it and offers a
/// manual retry + the swipe-down-to-dismiss `showModalBottomSheet` already
/// gives for free.
class OfflineBottomSheet extends ConsumerStatefulWidget {
  const OfflineBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      // Auto-dismissed by ConnectivityGate once back online — this isn't
      // the only way out, though: barrier tap / swipe-down still closes it,
      // per Blueprint Section 5's "manual close is still available".
      builder: (_) => const OfflineBottomSheet(),
    );
  }

  @override
  ConsumerState<OfflineBottomSheet> createState() => _OfflineBottomSheetState();
}

class _OfflineBottomSheetState extends ConsumerState<OfflineBottomSheet> {
  bool _retrying = false;

  Future<void> _retry() async {
    setState(() => _retrying = true);
    // Forces a fresh probe rather than waiting for the next
    // connectivity_plus change event — useful when the connection *type*
    // never changed (e.g. still on the same Wi-Fi) but reachability did
    // (router regained its upstream link).
    await ref.refresh(isOnlineProvider.future).catchError((_) => false);
    if (mounted) setState(() => _retrying = false);
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<LobbyPalette>() ?? LobbyPalette.standard;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.cardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 20),
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: palette.gradientStart.withValues(alpha: 0.1),
                  border: Border.all(color: palette.gradientStart.withValues(alpha: 0.3), width: 1.4),
                ),
                alignment: Alignment.center,
                child: AppIcon(HugeIcons.strokeRoundedWifiOff01, color: palette.gradientStart, size: 40),
              ),
              const SizedBox(height: 20),
              Text("You're offline", style: AppTextStyles.headline.copyWith(color: Colors.black87)),
              const SizedBox(height: 8),
              Text(
                'Check your connection and try again.',
                textAlign: TextAlign.center,
                style: AppTextStyles.body.copyWith(color: Colors.black54),
              ),
              const SizedBox(height: 24),
              PrimaryPillButton(label: 'Retry', loading: _retrying, onPressed: _retrying ? null : _retry),
            ],
          ),
        ),
      ),
    );
  }
}
