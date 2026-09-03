import 'package:flutter/material.dart';

import '../theme/lobby_palette.dart';

/// Wraps a lobby-register screen (Play/Friends/Profile, and any sub-screen
/// pushed from them) in the violet→magenta→orange gradient background.
///
/// The gradient wraps the **entire** [Scaffold], not just [body] — an
/// earlier version only wrapped `body`, so a transparent [appBar] showed the
/// plain theme background behind it instead of the gradient (white AppBar
/// text on a near-white background is essentially invisible). Wrapping the
/// whole Scaffold means the gradient is continuous behind the app bar too,
/// with no seam and no extra top-padding math needed in `body`. Demo:
/// ```dart
/// GradientScaffold(body: Center(child: Text('Play')))
/// ```
class GradientScaffold extends StatelessWidget {
  const GradientScaffold({super.key, required this.body, this.appBar, this.floatingActionButton});

  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<LobbyPalette>() ?? LobbyPalette.standard;
    return DecoratedBox(
      decoration: BoxDecoration(gradient: palette.backgroundGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: appBar,
        floatingActionButton: floatingActionButton,
        body: body,
      ),
    );
  }
}
