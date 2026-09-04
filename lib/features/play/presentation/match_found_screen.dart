import 'package:flutter/material.dart';

import '../../../core/widgets/duel_vs_transition.dart';
import '../../duel/presentation/duel_screen.dart';

/// Shown once matchmaking pairs two players: plays the [DuelVsTransition]
/// (built in Section 4) as the dramatic pre-match beat, then hands off to
/// [DuelScreen] — the duel feature owns everything from there (master
/// prompt Section 7, point 3).
class MatchFoundScreen extends StatefulWidget {
  const MatchFoundScreen({super.key, required this.matchId, required this.opponentName});

  final String matchId;
  final String opponentName;

  @override
  State<MatchFoundScreen> createState() => _MatchFoundScreenState();
}

class _MatchFoundScreenState extends State<MatchFoundScreen> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DuelVsTransition(
        controller: _controller,
        leftLabel: 'You',
        rightLabel: widget.opponentName,
        onComplete: () {
          Navigator.of(
            context,
          ).pushReplacement(MaterialPageRoute(builder: (_) => DuelScreen(opponentName: widget.opponentName)));
        },
      ),
    );
  }
}
