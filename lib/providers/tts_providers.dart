// Coach-voice provider seam (Phase 16, PRES-02). Mirrors audio_providers.dart:
// a Riverpod Provider that returns the real on-device speaker and disposes its
// native engine handle on teardown so resources do not leak. Tests override this
// provider with NoopTtsCoachSpeaker (no real synthesis in widget/unit tests).
//
// Riverpod-only (CLAUDE.md Decided — BLoC/GetX rejected).
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../tutor/tts_coach_speaker.dart';

/// The app's coach-voice speaker. Returns the real [TtsCoachSpeaker], which
/// voices a mixed en/ar coaching line per-script on-device and gracefully
/// degrades when the Arabic voice is absent — never throwing, never blocking the
/// trace loop (ADR-014 display-only).
///
/// The single native engine handle is released when the provider is torn down
/// (ref.onDispose → speaker.dispose) so platform TTS resources do not leak.
/// Tests override this provider with [NoopTtsCoachSpeaker].
final ttsCoachSpeakerProvider = Provider<CoachSpeaker>((ref) {
  final speaker = TtsCoachSpeaker();
  ref.onDispose(speaker.dispose);
  return speaker;
});
