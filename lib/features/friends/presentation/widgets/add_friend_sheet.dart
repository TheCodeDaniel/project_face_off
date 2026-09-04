import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:project_face_off/core/extensions/size_extensions.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/lobby_palette.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../core/widgets/pin_code_entry.dart';
import '../friends_providers.dart';

/// Add-friend flow (master prompt Section 9): share your own invite code, or
/// enter someone else's via [PinCodeEntry] (Blueprint Section 3's join-room
/// pattern, reused here). `useRootNavigator: true` for the same reason as
/// `HowToPlaySheet` — see CLAUDE.md engineering rule 9.
class AddFriendSheet extends ConsumerStatefulWidget {
  const AddFriendSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddFriendSheet(),
    );
  }

  @override
  ConsumerState<AddFriendSheet> createState() => _AddFriendSheetState();
}

class _AddFriendSheetState extends ConsumerState<AddFriendSheet> {
  bool _sent = false;
  String? _error;

  Future<void> _submitCode(String code) async {
    setState(() => _error = null);
    try {
      await ref.read(friendsRepositoryProvider).sendRequestByCode(code);
      if (!mounted) return;
      setState(() => _sent = true);
      // Auto-close once the confirmation has had a moment to register —
      // nothing left for the player to do here once a request is sent.
      Timer(const Duration(milliseconds: 1300), () {
        if (mounted) Navigator.of(context).pop();
      });
    } catch (_) {
      if (mounted) setState(() => _error = "That code didn't work — double-check and try again.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<LobbyPalette>() ?? LobbyPalette.standard;
    final myCode = ref.watch(friendsRepositoryProvider).myInviteCode;

    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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
              Text('Add a Friend', style: AppTextStyles.headline.copyWith(color: Colors.black87)),
              const SizedBox(height: 16),
              Text('Your code', style: AppTextStyles.label.copyWith(color: Colors.black45)),
              const SizedBox(height: 4),
              Text(myCode, style: AppTextStyles.numericLarge.copyWith(color: palette.gradientStart, fontSize: 30)),
              const SizedBox(height: 24),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _sent ? const _RequestSentConfirmation() : _CodeEntry(error: _error, onCompleted: _submitCode),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CodeEntry extends StatelessWidget {
  const _CodeEntry({required this.error, required this.onCompleted});

  final String? error;
  final ValueChanged<String> onCompleted;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('entry'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Enter a friend\'s code', style: AppTextStyles.label.copyWith(color: Colors.black45)),
        const SizedBox(height: 12),
        PinCodeEntry(onCompleted: onCompleted),
        if (error != null) ...[
          const SizedBox(height: 10),
          Text(error!, style: AppTextStyles.label.copyWith(color: Colors.red)),
        ],
      ],
    );
  }
}

class _RequestSentConfirmation extends StatelessWidget {
  const _RequestSentConfirmation();

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF2FAE66);
    return Container(
      width: context.screenWidth,
      key: const ValueKey('sent'),
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppIcon(HugeIcons.strokeRoundedCheckmarkCircle02, color: green, size: 40),
          const SizedBox(height: 10),
          Text('Request sent! 👍', style: AppTextStyles.headline.copyWith(color: green, fontSize: 18)),
        ],
      ),
    );
  }
}
