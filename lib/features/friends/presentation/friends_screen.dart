import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/gradient_scaffold.dart';
import '../../app_shell/presentation/nav_visibility_controller.dart';

/// Friends tab (master prompt Section 9): list, add-via-link/PIN, incoming
/// requests, report/block. Firestore-backed data layer not wired yet — see
/// CLAUDE.md.
class FriendsScreen extends StatelessWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
              const SizedBox(height: 24),
              Text(
                'No friends yet — add one to get started.',
                style: AppTextStyles.body.copyWith(color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
