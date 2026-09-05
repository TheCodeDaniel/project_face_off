/// Which MediaPipe Tasks Vision landmarker a [GameModule] needs running for
/// its match. `core/gesture_engine/` uses this to initialize only the
/// pipeline(s) the active game actually requires (multi-game plan Section
/// 3.4) — Face Off needs face-only, Bow & Draw needs hand-only, Freeze reuses
/// whatever's already active rather than declaring its own.
enum LandmarkerType { face, hand }
