import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';

import 'connectivity_service.dart';

/// [ConnectivityService] backed by `connectivity_plus` plus a real
/// reachability probe. Knowing the device is *associated* with a Wi-Fi/
/// cellular network isn't the same as having working internet (captive
/// portals, a router with no upstream link, ...) — Blueprint Section 5
/// calls this out explicitly as "loss of connection **or failed server
/// reachability check**". There's no real backend yet to health-check
/// against (see CLAUDE.md — Firebase isn't wired up), so this resolves a
/// stable public DNS name as a stand-in; swap the target for a real
/// Firebase health-check endpoint once one exists, the rest of this class
/// doesn't need to change.
class LiveConnectivityService implements ConnectivityService {
  LiveConnectivityService({Connectivity? connectivity}) : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  @override
  Stream<bool> get isOnline async* {
    yield await _probe();
    await for (final _ in _connectivity.onConnectivityChanged) {
      yield await _probe();
    }
  }

  Future<bool> _probe() async {
    final results = await _connectivity.checkConnectivity();
    if (results.every((r) => r == ConnectivityResult.none)) return false;
    return _reachable();
  }

  Future<bool> _reachable() async {
    try {
      final result = await InternetAddress.lookup('one.one.one.one').timeout(const Duration(seconds: 4));
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}
