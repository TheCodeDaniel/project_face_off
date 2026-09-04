import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether the live match is currently paused for a local connectivity
/// loss (master prompt Section 12) — separate from [DuelController]'s own
/// `RoundState` because pausing doesn't change the round state itself
/// (there's nothing to show mid-pause other than "waiting to reconnect"),
/// so folding it into `RoundState` would mean adding a state the round
/// state machine's own domain logic (`DuelRoundEngine`) has no reason to
/// know about. `DuelController` sets this from its connectivity handler;
/// `DuelScreen` watches it to show the reconnecting banner.
final duelOfflinePauseProvider = StateProvider.autoDispose<bool>((ref) => false);
