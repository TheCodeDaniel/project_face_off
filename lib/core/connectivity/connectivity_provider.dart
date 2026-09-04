import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Global online/offline stream (Blueprint Section 5). The duel feature and
/// any other feature consume [isOnlineProvider] rather than reimplementing
/// detection logic.
final connectivityStreamProvider = StreamProvider<List<ConnectivityResult>>((ref) {
  return Connectivity().onConnectivityChanged;
});

/// True once the device reports at least one non-`none` connectivity result.
/// Note: this reflects link-level connectivity, not actual server
/// reachability — pair with a health-check ping before trusting it for
/// reconnect logic in the duel feature.
final isOnlineProvider = Provider<bool>((ref) {
  final result = ref.watch(connectivityStreamProvider);
  return result.maybeWhen(data: (results) => results.any((r) => r != ConnectivityResult.none), orElse: () => true);
});
