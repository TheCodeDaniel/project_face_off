import 'package:flutter/material.dart';
import 'package:showcaseview/showcaseview.dart';

import '../theme/app_text_styles.dart';
import '../theme/lobby_palette.dart';
import 'tour_keys.dart';

/// On-brand, consistent styling for every [Showcase] in the post-sign-in
/// product tour (Section 6) — a frosted deep-violet tooltip with the app's
/// own type/color tokens, rather than the package's plain default white
/// card, so the tour reads as part of Face Off instead of a bolted-on
/// library widget.
Showcase tourShowcase({
  required GlobalKey key,
  required String title,
  required String description,
  required Widget child,
  ShapeBorder targetShapeBorder = const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
}) {
  const palette = LobbyPalette.standard;
  return Showcase(
    key: key,
    title: title,
    description: description,
    targetShapeBorder: targetShapeBorder,
    targetPadding: const EdgeInsets.all(6),
    tooltipBackgroundColor: palette.gradientStart,
    textColor: Colors.white,
    titleTextStyle: AppTextStyles.headline.copyWith(color: Colors.white, fontSize: 16),
    descTextStyle: AppTextStyles.body.copyWith(color: Colors.white70),
    tooltipBorderRadius: BorderRadius.circular(18),
    tooltipPadding: const EdgeInsets.all(16),
    blurValue: 2,
    tooltipActionConfig: const TooltipActionConfig(position: TooltipActionPosition.outside, actionGap: 8),
    child: child,
  );
}

/// Shared "Skip" / "Next" / "Got it" actions for [ShowcaseView.register]'s
/// `globalTooltipActions` — one definition reused across every step instead
/// of each `Showcase` hand-rolling its own buttons. "Skip" hides itself on
/// the last step (nothing left to skip); "Next" swaps for "Got it" there,
/// which still just calls the same `.next` action — `ShowcaseView.next()`
/// finishes the whole tour automatically when there's no step left.
List<TooltipActionButton> tourActions() {
  const palette = LobbyPalette.standard;
  final labelStyle = AppTextStyles.label;
  return [
    TooltipActionButton(
      type: TooltipDefaultActionType.skip,
      backgroundColor: Colors.white.withValues(alpha: 0.16),
      textStyle: labelStyle.copyWith(color: Colors.white),
      hideActionWidgetForShowcase: [TourKeys.profileNav],
    ),
    TooltipActionButton(
      type: TooltipDefaultActionType.next,
      backgroundColor: palette.coinGold,
      textStyle: labelStyle.copyWith(color: Colors.black87),
      hideActionWidgetForShowcase: [TourKeys.profileNav],
    ),
    TooltipActionButton(
      type: TooltipDefaultActionType.next,
      name: 'Got it',
      backgroundColor: palette.coinGold,
      textStyle: labelStyle.copyWith(color: Colors.black87),
      hideActionWidgetForShowcase: [TourKeys.quickMatch, TourKeys.friendsNav],
    ),
  ];
}
