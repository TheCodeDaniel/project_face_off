import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/gradient_scaffold.dart';
import '../../../core/widgets/match_found_screen.dart';
import '../domain/matchmaking_state.dart';
import 'matchmaking_controller.dart';
import 'widgets/matchmaking_searching_view.dart';
import 'widgets/matchmaking_timeout_view.dart';

/// Full-screen matchmaking queue (master prompt Section 7). [PlayScreen]
/// pushes this on the **root** Navigator, not the Play tab's own nested one
/// — a tab's nested Navigator is a Stack sibling that `AppShellScreen`
/// paints *underneath* `FloatingNavBar`, so a full-screen route pushed there
/// would render behind the nav bar instead of covering it (the same bug
/// class as the modal-sheet fix on `HowToPlaySheet`). Everything this
/// screen hands off to (`MatchFoundScreen`, the matched game's own screen)
/// inherits the root Navigator automatically via ordinary
/// `Navigator.of(context)` calls, since by the time they're pushed this
/// screen's subtree already lives there.
class MatchmakingScreen extends ConsumerStatefulWidget {
  const MatchmakingScreen({super.key});

  @override
  ConsumerState<MatchmakingScreen> createState() => _MatchmakingScreenState();
}

class _MatchmakingScreenState extends ConsumerState<MatchmakingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => ref.read(matchmakingControllerProvider.notifier).startQueue());
  }

  void _cancel() {
    ref.read(matchmakingControllerProvider.notifier).cancelQueue();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(matchmakingControllerProvider, (previous, next) {
      if (next is MatchmakingFound) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) =>
                MatchFoundScreen(matchId: next.matchId, opponentId: next.opponentId, opponentName: next.opponentName),
          ),
        );
      }
    });

    final state = ref.watch(matchmakingControllerProvider);

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) ref.read(matchmakingControllerProvider.notifier).cancelQueue();
      },
      child: GradientScaffold(
        body: SafeArea(
          child: Center(
            child: switch (state) {
              MatchmakingIdle() || MatchmakingSearching() => MatchmakingSearchingView(onCancel: _cancel),
              MatchmakingFound() => const SizedBox.shrink(),
              MatchmakingTimedOut() => MatchmakingTimeoutView(
                onRetry: () => ref.read(matchmakingControllerProvider.notifier).startQueue(),
                onCancel: _cancel,
              ),
            },
          ),
        ),
      ),
    );
  }
}
