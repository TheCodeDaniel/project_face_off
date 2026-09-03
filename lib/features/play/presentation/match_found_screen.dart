import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/match_palette.dart';
import '../../../core/widgets/duel_vs_transition.dart';
import '../../../core/widgets/primary_pill_button.dart';

/// Shown once matchmaking pairs two players: plays the [DuelVsTransition]
/// (built in Section 4) as the dramatic pre-match beat, then hands off to
/// the duel feature — Section 8's live match screen isn't wired up to a real
/// route yet (its game-engine and networking are still being built; see
/// CLAUDE.md), so this is the intentional bridge/stopping point for now
/// rather than a silent dead end.
class MatchFoundScreen extends StatefulWidget {
  const MatchFoundScreen({super.key, required this.matchId, required this.opponentName});

  final String matchId;
  final String opponentName;

  @override
  State<MatchFoundScreen> createState() => _MatchFoundScreenState();
}

class _MatchFoundScreenState extends State<MatchFoundScreen> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
  bool _transitionDone = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<MatchPalette>() ?? MatchPalette.standard;
    return Scaffold(
      body: _transitionDone
          ? DecoratedBox(
              decoration: BoxDecoration(gradient: palette.backgroundGradient),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Duel screen lands in the next phase',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.headline.copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Matched with ${widget.opponentName} — the live gesture-duel screen (Section 8) is still being built.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.body.copyWith(color: Colors.white70),
                      ),
                      const SizedBox(height: 32),
                      PrimaryPillButton(
                        label: 'Back to Play',
                        icon: HugeIcons.strokeRoundedArrowLeft01,
                        onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : DuelVsTransition(
              controller: _controller,
              leftLabel: 'You',
              rightLabel: widget.opponentName,
              onComplete: () => setState(() => _transitionDone = true),
            ),
    );
  }
}
