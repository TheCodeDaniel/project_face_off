import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'connectivity_service.dart';
import 'live_connectivity_service.dart';

final connectivityServiceProvider = Provider<ConnectivityService>((ref) => LiveConnectivityService());

/// Single shared online/offline signal — [ConnectivityGate] (the app-wide
/// offline sheet) and the duel feature's mid-match pause/forfeit logic both
/// watch this instead of each standing up their own detector.
final isOnlineProvider = StreamProvider<bool>((ref) => ref.watch(connectivityServiceProvider).isOnline);
