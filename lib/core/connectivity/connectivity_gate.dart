import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/offline_bottom_sheet.dart';
import 'connectivity_providers.dart';

/// Mounts [isOnlineProvider] once for the whole app shell and shows/
/// auto-dismisses [OfflineBottomSheet] in response (master prompt Section
/// 12) — "the instant connectivity is restored ... no manual dismiss
/// needed". Renders [child] untouched; this widget only exists for the
/// `ref.listen` side effect, so wrap it around the shell rather than
/// scattering the same listener across every screen.
class ConnectivityGate extends ConsumerStatefulWidget {
  const ConnectivityGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<ConnectivityGate> createState() => _ConnectivityGateState();
}

class _ConnectivityGateState extends ConsumerState<ConnectivityGate> {
  bool _sheetShown = false;

  @override
  Widget build(BuildContext context) {
    ref.listen(isOnlineProvider, (previous, next) {
      final isOnline = next.valueOrNull ?? true;
      if (!isOnline && !_sheetShown) {
        _sheetShown = true;
        OfflineBottomSheet.show(context).whenComplete(() => _sheetShown = false);
      } else if (isOnline && _sheetShown) {
        // A manual swipe-down/barrier-tap dismiss also clears _sheetShown
        // via the .whenComplete above, so this pop is a no-op in that case
        // rather than a double-dismiss.
        Navigator.of(context, rootNavigator: true).maybePop();
      }
    });
    return widget.child;
  }
}
