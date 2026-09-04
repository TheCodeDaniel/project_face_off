import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether the live match is currently paused for a local connectivity loss
/// (master prompt Section 12) — separate from [MatchController]'s own
/// `MatchState` because pausing doesn't change match state itself (there's
/// nothing to show mid-pause other than "waiting to reconnect"), so folding
/// it in would mean adding a state no game's domain logic has any reason to
/// know about. `MatchController` sets this from its connectivity handler;
/// the active game's screen watches it to show a reconnecting banner.
final matchOfflinePauseProvider = StateProvider.autoDispose<bool>((ref) => false);
