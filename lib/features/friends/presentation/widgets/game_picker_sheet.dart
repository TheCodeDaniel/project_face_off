import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../core/game_engine/game_pool.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/lobby_palette.dart';
import '../../../../core/widgets/app_icon.dart';

/// What the player picked in [GamePickerSheet] — a specific game, or
/// "Surprise me" (still resolved to one specific game, same
/// `pickRandomGameId()` mechanism Quick Match uses, just triggered from a
/// friend-challenge flow instead). `null` from [GamePickerSheet.show] means
/// the sheet was dismissed without a choice — distinct from surprise-me,
/// which is itself a real choice with a null [gameId].
class GamePickerChoice {
  const GamePickerChoice.specific(GameId this.gameId) : isSurpriseMe = false;
  const GamePickerChoice.surpriseMe() : gameId = null, isSurpriseMe = true;

  final GameId? gameId;
  final bool isSurpriseMe;
}

/// Lets the challenger pick a specific game for a private friend match, or
/// "Surprise me" for a random one (multi-game plan Section 4.1) — safe to
/// offer a specific-game choice here, unlike Quick Match, since a 1:1
/// challenge has no shared queue to fragment.
class GamePickerSheet extends StatelessWidget {
  const GamePickerSheet({super.key});

  static Future<GamePickerChoice?> show(BuildContext context) {
    return showModalBottomSheet<GamePickerChoice>(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const GamePickerSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                child: Text('Pick a game', style: AppTextStyles.headline.copyWith(color: Colors.black87)),
              ),
              const SizedBox(height: 8),
              // Only games with a real GameModule built are offered —
              // implementedGameIds grows as Bow & Draw/Freeze ship, no other
              // change needed here.
              for (final definition in gamePool.where((g) => implementedGameIds.contains(g.id)))
                _GameTile(
                  icon: HugeIcons.strokeRoundedBoxingGlove01,
                  label: definition.displayName,
                  onTap: () => Navigator.of(context).pop(GamePickerChoice.specific(definition.id)),
                ),
              _GameTile(
                icon: HugeIcons.strokeRoundedDiceFaces01,
                label: 'Surprise me',
                onTap: () => Navigator.of(context).pop(const GamePickerChoice.surpriseMe()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GameTile extends StatelessWidget {
  const _GameTile({required this.icon, required this.label, required this.onTap});

  final List<List<dynamic>> icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: AppIcon(icon, color: Colors.black87, size: 20),
      title: Text(label, style: AppTextStyles.body.copyWith(color: Colors.black87)),
    );
  }
}
