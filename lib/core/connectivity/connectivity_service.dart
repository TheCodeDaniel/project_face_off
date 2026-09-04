/// Global online/offline signal (master prompt Section 12, Blueprint
/// Section 5) — a `connectivity_plus` stream feeding a single provider, so
/// every consumer (the app-wide offline sheet, the duel feature's mid-match
/// pause/forfeit logic) shares one detector instead of each reimplementing
/// it.
abstract class ConnectivityService {
  /// Emits the current online state immediately on listen, then again
  /// whenever it changes.
  Stream<bool> get isOnline;
}
