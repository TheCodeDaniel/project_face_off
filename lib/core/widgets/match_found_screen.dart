import 'dart:async';

import 'package:flutter/material.dart';

import '../game_engine/game_pool.dart';
import '../game_engine/game_screen_factory.dart';
import '../theme/match_palette.dart';
import 'duel_vs_transition.dart';
import 'game_rules_card.dart';

/// Shown once matchmaking pairs two players (or a friend challenge is
/// confirmed — see `GamePickerSheet`): briefly shows a [GameRulesCard] for
/// whichever game was picked, then plays the [DuelVsTransition] (built in
/// Section 4) as the dramatic pre-match beat, then hands off to that game's
/// own screen via [buildGameScreen] — this screen never hardcodes a single
/// game (multi-game plan Section 3.5).
///
/// [presetGameId] lets a direct friend challenge specify a game (or "Surprise
/// me" by passing null, same as Quick Match); Quick Match itself always
/// passes null. Whichever value is used, it's resolved exactly once here
/// (not re-picked on every rebuild) so the rules card and the match itself
/// agree on the same game.
class MatchFoundScreen extends StatefulWidget {
  const MatchFoundScreen({
    super.key,
    required this.matchId,
    required this.opponentId,
    required this.opponentName,
    this.presetGameId,
  });

  final String matchId;
  final String opponentId;
  final String opponentName;
  final GameId? presetGameId;

  @override
  State<MatchFoundScreen> createState() => _MatchFoundScreenState();
}

class _MatchFoundScreenState extends State<MatchFoundScreen> with SingleTickerProviderStateMixin {
  static const _rulesCardDuration = Duration(milliseconds: 1800);

  late final _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
  late final GameId _gameId = widget.presetGameId ?? pickRandomGameId();
  Timer? _rulesTimer;
  bool _showingRules = true;

  @override
  void initState() {
    super.initState();
    _rulesTimer = Timer(_rulesCardDuration, () {
      if (mounted) setState(() => _showingRules = false);
    });
  }

  @override
  void dispose() {
    _rulesTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_showingRules) {
      final palette = Theme.of(context).extension<MatchPalette>() ?? MatchPalette.standard;
      return Scaffold(
        body: DecoratedBox(
          decoration: BoxDecoration(gradient: palette.backgroundGradient),
          child: Center(child: GameRulesCard(gameId: _gameId)),
        ),
      );
    }

    return Scaffold(
      body: DuelVsTransition(
        controller: _controller,
        leftLabel: 'You',
        rightLabel: widget.opponentName,
        onComplete: () {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => buildGameScreen(
                _gameId,
                matchId: widget.matchId,
                opponentId: widget.opponentId,
                opponentName: widget.opponentName,
              ),
            ),
          );
        },
      ),
    );
  }
}
