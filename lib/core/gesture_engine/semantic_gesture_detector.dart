import 'dart:async';
import 'dart:isolate';

import 'blendshape_frame.dart';
import 'gesture_engine.dart';
import 'gesture_thresholds.dart';
import 'semantic_gesture_event.dart';

/// Subscribes to a [GestureEngine]'s raw frame stream and applies the
/// thresholding logic on a long-lived [Isolate] (master prompt Section 8.6 /
/// engineering constraint 7 — never on the UI isolate), emitting debounced
/// [SemanticGestureEvent]s.
///
/// Debounce state (consecutive over-threshold frame counters) lives entirely
/// inside the isolate; only semantic events cross back to the UI isolate.
class SemanticGestureDetector {
  SemanticGestureDetector(this._engine);

  final GestureEngine _engine;
  final _eventsController = StreamController<SemanticGestureEvent>.broadcast();
  StreamSubscription<BlendshapeFrame>? _frameSub;
  Isolate? _isolate;
  SendPort? _toIsolate;

  Stream<SemanticGestureEvent> get events => _eventsController.stream;

  Future<void> start() async {
    final receivePort = ReceivePort();
    _isolate = await Isolate.spawn(_thresholdIsolateEntry, receivePort.sendPort);

    final toIsolateCompleter = Completer<SendPort>();
    receivePort.listen((message) {
      if (message is SendPort) {
        toIsolateCompleter.complete(message);
      } else if (message is SemanticGestureEvent) {
        _eventsController.add(message);
      }
    });
    _toIsolate = await toIsolateCompleter.future;

    await _engine.start();
    _frameSub = _engine.frames.listen((frame) => _toIsolate?.send(frame));
  }

  Future<void> stop() async {
    await _frameSub?.cancel();
    await _engine.stop();
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
  }

  Future<void> dispose() async {
    await stop();
    await _eventsController.close();
  }
}

void _thresholdIsolateEntry(SendPort mainSendPort) {
  final receivePort = ReceivePort();
  mainSendPort.send(receivePort.sendPort);

  var fireStreak = 0;
  var dodgeStreak = 0;
  var crackStreak = 0;

  receivePort.listen((message) {
    if (message is! BlendshapeFrame) return;

    fireStreak = message.jawOpen >= GestureThresholds.fireJawOpen ? fireStreak + 1 : 0;
    dodgeStreak = message.browInnerUp >= GestureThresholds.dodgeBrowRaise ? dodgeStreak + 1 : 0;
    crackStreak = message.mouthCurvature >= GestureThresholds.crackCurvature ? crackStreak + 1 : 0;

    // Crack detection must feel instant (master prompt 8.4) — no debounce.
    if (message.mouthCurvature >= GestureThresholds.crackCurvature) {
      mainSendPort.send(CrackDetected(timestamp: message.timestamp));
    }
    if (fireStreak == GestureThresholds.debounceFrameCount) {
      mainSendPort.send(FireDetected(timestamp: message.timestamp));
    }
    if (dodgeStreak == GestureThresholds.debounceFrameCount) {
      mainSendPort.send(DodgeDetected(timestamp: message.timestamp));
    }
  });
}
