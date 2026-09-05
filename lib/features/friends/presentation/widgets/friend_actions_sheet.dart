import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/lobby_palette.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../core/widgets/match_found_screen.dart';
import '../../domain/friend.dart';
import '../friends_providers.dart';
import 'game_picker_sheet.dart';
import 'report_user_sheet.dart';

/// Per-friend action sheet (master prompt Section 9): challenge to a private
/// match, report, block, unfriend.
class FriendActionsSheet extends ConsumerWidget {
  const FriendActionsSheet({super.key, required this.friend});

  final Friend friend;

  static Future<void> show(BuildContext context, Friend friend) {
    return showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FriendActionsSheet(friend: friend),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = Theme.of(context).extension<LobbyPalette>() ?? LobbyPalette.standard;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.cardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(friend.displayName, style: AppTextStyles.headline.copyWith(color: Colors.black87)),
              ),
              const SizedBox(height: 8),
              _ActionTile(
                icon: HugeIcons.strokeRoundedBoxingGlove01,
                label: 'Challenge to a private match',
                onTap: () async {
                  // Captured before the await — GamePickerSheet.show shows
                  // on top of this still-open actions sheet (both live on
                  // the root Navigator), so this sheet's own context stays
                  // valid throughout, but the Navigator reference is grabbed
                  // up front anyway as the safer habit for any future edit
                  // that reorders this.
                  final rootNavigator = Navigator.of(context, rootNavigator: true);
                  final choice = await GamePickerSheet.show(context);
                  if (choice == null) return;
                  rootNavigator.pop();
                  rootNavigator.push(
                    MaterialPageRoute(
                      builder: (_) => MatchFoundScreen(
                        matchId: 'private-${friend.id}',
                        opponentId: friend.id,
                        opponentName: friend.displayName,
                        presetGameId: choice.gameId,
                      ),
                    ),
                  );
                },
              ),
              _ActionTile(
                icon: HugeIcons.strokeRoundedFlag02,
                label: 'Report',
                onTap: () {
                  Navigator.of(context).pop();
                  ReportUserSheet.show(context, userId: friend.id, displayName: friend.displayName);
                },
              ),
              _ActionTile(
                icon: HugeIcons.strokeRoundedCancelCircle,
                label: 'Block',
                destructive: true,
                onTap: () {
                  ref.read(friendsRepositoryProvider).blockUser(friend.id);
                  Navigator.of(context).pop();
                },
              ),
              _ActionTile(
                icon: HugeIcons.strokeRoundedUserRemove01,
                label: 'Unfriend',
                destructive: true,
                onTap: () {
                  ref.read(friendsRepositoryProvider).unfriend(friend.id);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.icon, required this.label, required this.onTap, this.destructive = false});

  final List<List<dynamic>> icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? Colors.red.shade400 : Colors.black87;
    return ListTile(
      onTap: onTap,
      leading: AppIcon(icon, color: color, size: 20),
      title: Text(label, style: AppTextStyles.body.copyWith(color: color)),
    );
  }
}
