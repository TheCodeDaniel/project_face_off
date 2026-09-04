import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/gradient_scaffold.dart';
import '../../../core/widgets/primary_pill_button.dart';
import '../../app_shell/presentation/nav_visibility_controller.dart';
import 'friends_providers.dart';
import 'widgets/add_friend_sheet.dart';
import 'widgets/friend_actions_sheet.dart';
import 'widgets/friend_list_tile.dart';
import 'widgets/friend_request_tile.dart';

/// Friends tab (master prompt Section 9): incoming requests, friends list,
/// add-friend entry point.
class FriendsScreen extends ConsumerWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friends = ref.watch(friendsListProvider).valueOrNull ?? const [];
    final requests = ref.watch(incomingRequestsProvider).valueOrNull ?? const [];
    final repo = ref.read(friendsRepositoryProvider);

    return GradientScaffold(
      body: SafeArea(
        child: NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification is ScrollUpdateNotification) {
              NavVisibilityScope.of(context).onScrollDelta(notification.scrollDelta ?? 0);
            }
            return false;
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
            children: [
              Text('Friends', style: AppTextStyles.display.copyWith(color: Colors.white)),
              const SizedBox(height: 20),
              PrimaryPillButton(
                label: 'Add Friend',
                icon: HugeIcons.strokeRoundedUserAdd01,
                onPressed: () => AddFriendSheet.show(context),
              ),
              if (requests.isNotEmpty) ...[
                const SizedBox(height: 28),
                Text('Requests', style: AppTextStyles.label.copyWith(color: Colors.white70)),
                const SizedBox(height: 10),
                for (final request in requests)
                  FriendRequestTile(
                    request: request,
                    onAccept: () => repo.acceptRequest(request.id),
                    onDecline: () => repo.declineRequest(request.id),
                  ),
              ],
              const SizedBox(height: 28),
              Text('Friends', style: AppTextStyles.label.copyWith(color: Colors.white70)),
              const SizedBox(height: 10),
              if (friends.isEmpty)
                const _EmptyFriendsList()
              else
                for (final friend in friends)
                  FriendListTile(friend: friend, onTap: () => FriendActionsSheet.show(context, friend)),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyFriendsList extends StatelessWidget {
  const _EmptyFriendsList();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const AppIcon(HugeIcons.strokeRoundedUserGroup, color: Colors.white70, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'No friends yet — add one to challenge them to a private match.',
              style: AppTextStyles.body.copyWith(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }
}
