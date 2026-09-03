import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// "Players online now" trust signal (master prompt Section 7) — subtle, not
/// a pressure tactic. No real presence tracking exists yet (needs Firebase;
/// see CLAUDE.md), so this emits a plausible, gently fluctuating number
/// purely so the Play tab doesn't sit at a hardcoded 0. The `Timer.periodic`
/// is explicitly cancelled via `ref.onDispose` — an `async*` generator
/// looping on `Future.delayed` instead would leave a dangling platform timer
/// behind when the provider is torn down (surfaces as a failed
/// `!timersPending` assertion in widget tests).
final onlineCountProvider = StreamProvider<int>((ref) {
  final random = Random();
  var count = 120 + random.nextInt(80);
  final controller = StreamController<int>();
  controller.add(count);

  final timer = Timer.periodic(const Duration(seconds: 4), (_) {
    count = (count + random.nextInt(11) - 5).clamp(60, 400);
    controller.add(count);
  });

  ref.onDispose(() {
    timer.cancel();
    controller.close();
  });

  return controller.stream;
});
