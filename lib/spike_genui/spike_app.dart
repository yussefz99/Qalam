// THROWAWAY SPIKE — Phase 11 GenUI/native-canvas kill-shot (Plan 11-02, Task 3).
//
// PURPOSE: the A/B harness — the kill-shot itself. A plain MaterialApp (no router, no
// l10n, no theme provider) whose home is a SegmentedButton toggle between:
//   [A] EMBEDDED   — a GenUI `Surface` driven by GeminiTransport, rendering the
//                    present_activity tree (model coaching line + the REAL StrokeCanvas
//                    embedded under a stable key) — the seam the Phase 14 GATE turns on.
//   [B] STANDALONE — the SAME StrokeCanvas under a stable key with the SAME baa fixture,
//                    in a bare Scaffold — the kill-shot reference.
// Flipping between [A] and [B] lets the same baa trace be felt side-by-side (D-05): if the
// embedded pen feels identical to the standalone pen, GenUI can be kept; if the embedded
// pen lags or loses ink that the standalone keeps, that is the "drop GenUI" evidence.
//
// Verified against the INSTALLED genui 0.9.2 source: the render widget is `Surface`
// (Surface(surfaceContext: controller.contextFor(surfaceId))), NOT a "GenUiSurface".
//
// Dev-harness posture (mirrors lib/dev/glyph_audit_screen.dart): this is a DEBUG SEAM,
// reachable only via its own -t target, never surfaced in user-facing nav.
//
// StrokeCanvas is a plain StatefulWidget, so no ProviderScope is needed. This file edits
// no durable file (imports StrokeCanvas read-only); the SC-4 git-diff guard proves it.

import 'package:flutter/material.dart';
import 'package:genui/genui.dart';

// Durable widget imported READ-ONLY — the standalone arm hosts the REAL canvas.
import 'package:qalam/features/practice/widgets/stroke_canvas.dart';

import 'agent/gemini_transport.dart';
import 'fixtures/baa_reference.dart';

/// Stable identity for the STANDALONE canvas (arm B) — the kill-shot reference.
const ValueKey<String> kStandaloneCanvasKey = ValueKey<String>(
  'spike-standalone-canvas',
);

/// Which arm of the A/B harness is showing.
enum SpikeArm {
  /// [A] GenUI-embedded canvas (present_activity tree via Surface).
  embedded,

  /// [B] standalone canvas (bare Scaffold).
  standalone,
}

class SpikeApp extends StatelessWidget {
  const SpikeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Qalam GenUI Spike',
      debugShowCheckedModeBanner: false,
      home: const SpikeHarnessScreen(),
    );
  }
}

class SpikeHarnessScreen extends StatefulWidget {
  const SpikeHarnessScreen({super.key});

  @override
  State<SpikeHarnessScreen> createState() => _SpikeHarnessScreenState();
}

class _SpikeHarnessScreenState extends State<SpikeHarnessScreen> {
  SpikeArm _arm = SpikeArm.embedded;

  late final GeminiTransport _transport;

  /// The surfaceId GenUI adds when the model emits the present_activity tree.
  String? _surfaceId;

  /// A visible "drop" finding — set when the model/transport degrades (GATE data).
  Object? _dropError;

  @override
  void initState() {
    super.initState();
    _transport = GeminiTransport(
      onSurfaceAdded: (String surfaceId) {
        if (!mounted) return;
        setState(() => _surfaceId = surfaceId);
      },
      onDrop: (Object error) {
        if (!mounted) return;
        setState(() => _dropError = error);
      },
    );
    // Kick the present_activity loop so arm [A] has a tree to render.
    _transport.start();
  }

  @override
  void dispose() {
    _transport.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Qalam GenUI kill-shot — A/B'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: SegmentedButton<SpikeArm>(
              segments: const <ButtonSegment<SpikeArm>>[
                ButtonSegment<SpikeArm>(
                  value: SpikeArm.embedded,
                  label: Text('[A] GenUI-embedded'),
                  icon: Icon(Icons.auto_awesome),
                ),
                ButtonSegment<SpikeArm>(
                  value: SpikeArm.standalone,
                  label: Text('[B] Standalone'),
                  icon: Icon(Icons.edit),
                ),
              ],
              selected: <SpikeArm>{_arm},
              onSelectionChanged: (Set<SpikeArm> selection) {
                setState(() => _arm = selection.first);
              },
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: switch (_arm) {
          SpikeArm.embedded => _buildEmbeddedArm(context),
          SpikeArm.standalone => _buildStandaloneArm(),
        },
      ),
      // Spike-only kill-shot probe: forces a model-driven surface UPDATE (fresh
      // coaching line) WITHOUT switching arms — tests whether the embedded canvas
      // State + the child's in-progress ink survive a real tutor-loop update.
      floatingActionButton: _arm == SpikeArm.embedded
          ? FloatingActionButton.extended(
              onPressed: () => _transport.nudge(),
              icon: const Icon(Icons.refresh),
              label: const Text('Nudge coaching'),
            )
          : null,
    );
  }

  /// Arm [A]: the GenUI Surface rendering the present_activity tree. Non-scrolling
  /// region (Pitfall 2 — the Listener-based canvas loses drags inside a ScrollView).
  Widget _buildEmbeddedArm(BuildContext context) {
    if (_dropError != null) {
      return _DropFinding(error: _dropError!);
    }
    final String? surfaceId = _surfaceId;
    if (surfaceId == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Waiting for the model to present the activity…\n'
            '(needs Firebase AI Logic enabled — Plan 11-01 Task 3)',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return Surface(
      surfaceContext: _transport.controller.contextFor(surfaceId),
    );
  }

  /// Arm [B]: the SAME StrokeCanvas standalone, the kill-shot reference. Same stable
  /// key + same baa fixture as the embedded arm.
  Widget _buildStandaloneArm() {
    return const StrokeCanvas(
      key: kStandaloneCanvasKey,
      referenceStrokes: baaReferenceStrokes,
    );
  }
}

/// A visible "drop" finding — a failed model/transport call is GATE data, not a crash.
class _DropFinding extends StatelessWidget {
  const _DropFinding({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 12),
            const Text(
              'DROP finding: the GenUI present_activity loop failed.',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('$error', textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
