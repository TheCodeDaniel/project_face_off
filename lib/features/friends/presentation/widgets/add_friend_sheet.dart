import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/lobby_palette.dart';
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
      if (mounted) setState(() => _sent = true);
    } catch (_) {
      if (mounted) setState(() => _error = "That code didn't work — double-check and try again.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<LobbyPalette>() ?? LobbyPalette.standard;
    final myCode = ref.watch(friendsRepositoryProvider).myInviteCode;

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
              Text('Add a Friend', style: AppTextStyles.headline.copyWith(color: Colors.black87)),
              const SizedBox(height: 16),
              Text('Your code', style: AppTextStyles.label.copyWith(color: Colors.black45)),
              const SizedBox(height: 4),
              Text(myCode, style: AppTextStyles.numericLarge.copyWith(color: palette.gradientStart, fontSize: 30)),
              const SizedBox(height: 24),
              Text('Enter a friend\'s code', style: AppTextStyles.label.copyWith(color: Colors.black45)),
              const SizedBox(height: 12),
              _sent
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        'Request sent!',
                        style: AppTextStyles.headline.copyWith(color: const Color(0xFF2FAE66), fontSize: 18),
                      ),
                    )
                  : PinCodeEntry(onCompleted: _submitCode),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(_error!, style: AppTextStyles.label.copyWith(color: Colors.red)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
