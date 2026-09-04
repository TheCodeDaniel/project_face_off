import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/gradient_scaffold.dart';
import '../../../core/widgets/podium_leaderboard.dart';
import 'profile_providers.dart';
import 'widgets/leaderboard_scope_selector.dart';

/// Full leaderboard (master prompt Section 10): ranking by total round wins
/// (documented on `ProfileRepository`), scoped to Global or Friends via
/// [LeaderboardScopeSelector] — see `LeaderboardScope`'s doc comment for why
/// there's no Regional option.
class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scope = ref.watch(leaderboardScopeProvider);
    final entries = ref.watch(leaderboardProvider(scope)).valueOrNull ?? const [];
    return GradientScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: Text('Leaderboard', style: AppTextStyles.headline.copyWith(color: Colors.white)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          children: [
            Center(
              child: LeaderboardScopeSelector(
                scope: scope,
                onChanged: (value) => ref.read(leaderboardScopeProvider.notifier).state = value,
              ),
            ),
            const SizedBox(height: 20),
            PodiumLeaderboard(entries: entries),
          ],
        ),
      ),
    );
  }
}
