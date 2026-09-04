import 'dart:async';
import 'dart:isolate';
import 'dart:math';

import 'draw_gesture_event.dart';
import 'draw_gesture_thresholds.dart';
import 'hand_gesture_engine.dart';
import 'hand_landmark_frame.dart';

/// Subscribes to a [HandGestureEngine]'s raw frame stream and applies
/// anchor-establishment + draw-power + release/cancel detection on a
/// long-lived [Isolate] — same shape and same reason as
/// [SemanticGestureDetector] (engineering rule 7: never on the UI isolate).
///
/// All per-frame state (the rest anchor, streak counters, last-known
/// distance/openness) lives entirely inside the isolate; only semantic
/// [DrawGestureEvent]s cross back to the UI isolate.
class DrawGestureDetector {
  DrawGestureDetector(this._engine);

  final HandGestureEngine _engine;
  final _eventsController = StreamController<DrawGestureEvent>.broadcast();
  StreamSubscription<HandLandmarkFrame>? _frameSub;
  Isolate? _isolate;
  SendPort? _toIsolate;

  Stream<DrawGestureEvent> get events => _eventsController.stream;

  Future<void> start() async {
    final receivePort = ReceivePort();
    _isolate = await Isolate.spawn(_drawIsolateEntry, receivePort.sendPort);

    final toIsolateCompleter = Completer<SendPort>();
    receivePort.listen((message) {
      if (message is SendPort) {
        toIsolateCompleter.complete(message);
      } else if (message is DrawGestureEvent) {
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

void _drawIsolateEntry(SendPort mainSendPort) {
  final receivePort = ReceivePort();
  mainSendPort.send(receivePort.sendPort);

  double? anchorX;
  double? anchorY;
  double? prevX;
  double? prevY;
  double? lastDistance;
  double? lastPower;
  var lastOpenness = 0.0;
  var restStreak = 0;
  var noHandStreak = 0;

  void resetDraw() {
    anchorX = null;
    anchorY = null;
    prevX = null;
    prevY = null;
    lastDistance = null;
    lastPower = null;
    lastOpenness = 0;
    restStreak = 0;
  }

  receivePort.listen((message) {
    if (message is! HandLandmarkFrame) return;

    if (!message.handDetected) {
      noHandStreak++;
      if (noHandStreak == DrawGestureThresholds.occlusionGraceFrameCount && anchorX != null) {
        mainSendPort.send(DrawCancelled(timestamp: message.timestamp));
        resetDraw();
      }
      return;
    }
    noHandStreak = 0;

    // No anchor yet: wait for the hand to hold still, then lock in its
    // current position as the "at rest" draw origin.
    if (anchorX == null) {
      if (prevX != null && prevY != null) {
        final movement = sqrt(pow(message.pinchX - prevX!, 2) + pow(message.pinchY - prevY!, 2));
        restStreak = movement <= DrawGestureThresholds.anchorRestMovementTolerance ? restStreak + 1 : 0;
      }
      prevX = message.pinchX;
      prevY = message.pinchY;
      if (restStreak >= DrawGestureThresholds.anchorRestFrameCount) {
        anchorX = message.pinchX;
        anchorY = message.pinchY;
        restStreak = 0;
      }
      return;
    }

    final distance = sqrt(pow(message.pinchX - anchorX!, 2) + pow(message.pinchY - anchorY!, 2));
    final power = (distance / DrawGestureThresholds.calibratedMaxDrawDistance).clamp(0.0, 1.0);

    final dropRate = lastDistance == null ? 0.0 : lastDistance! - distance;
    final opennessIncrease = message.handOpenness - lastOpenness;
    final isRelease =
        lastDistance != null &&
        dropRate >= DrawGestureThresholds.releaseDistanceDropRate &&
        opennessIncrease >= DrawGestureThresholds.releaseOpennessIncrease;

    if (isRelease) {
      mainSendPort.send(DrawReleased(timestamp: message.timestamp, power: lastPower ?? power));
      resetDraw();
      return;
    }

    mainSendPort.send(DrawUpdate(timestamp: message.timestamp, power: power));
    lastDistance = distance;
    lastPower = power;
    lastOpenness = message.handOpenness;
  });
}
