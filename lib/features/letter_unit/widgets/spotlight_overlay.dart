// SpotlightOverlay — the "just this part" micro-drill chrome (Plan 18-10 Task 2 ·
// D-05 · sketch 002 Variant B "Spotlight").
//
// During a `type=='microDrill'` exercise the child practices ONE part of the
// letter (the dot / the bowl / the start). This overlay lights that part's zone
// and gently dims the rest — the WHOLE letter stays visible (a soft scrim, not an
// occlusion), so the child sees the letter in context while their eye is drawn to
// the part being drilled.
//
// PRESENTATIONAL ONLY (the hard D-05 invariant): this layer adds NO gesture
// handling and is wrapped in an [IgnorePointer], so it NEVER touches stroke
// capture — the existing StrokeCanvas still owns every pointer event and the
// scorer path is byte-unchanged. "The child still writes."
//
// ZONE → REGION: the micro-drill's `surface` is write-mode (no dotted guide), so
// there is no reference-path geometry to reuse; the lit zone is a fractional
// position keyed by the authored `spotlightZone` string (matching the sketch's
// fractional radial-gradient centre, e.g. the dot at ~50% / 84%). The exact
// pixel-fidelity to the reference glyph is a device-UAT refinement (18-11).

import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// A presentational spotlight/dim layer for a micro-drill. Lights the
/// [spotlightZone] region and dims the rest; inert (renders nothing) for an
/// unknown/absent zone. Layered by [WriteSurface] ONLY when the exercise is a
/// `type=='microDrill'`.
class SpotlightOverlay extends StatelessWidget {
  const SpotlightOverlay({super.key, required this.spotlightZone});

  /// The authored lit-region label from the drill config: `dot` / `bowl` /
  /// `start`. Null or unrecognised → the overlay is inert.
  final String? spotlightZone;

  @override
  Widget build(BuildContext context) {
    final align = _zoneAlignment(spotlightZone);
    if (align == null) return const SizedBox.shrink();
    // IgnorePointer is the whole safety story: the scrim paints over the canvas
    // but every pointer event falls straight through to the StrokeCanvas below.
    return IgnorePointer(
      child: CustomPaint(
        painter: _SpotlightPainter(align),
        size: Size.infinite,
      ),
    );
  }

  /// The lit-zone centre as an [Alignment] (x,y in −1..1). Baa is written R→L, so
  /// `start` sits upper-right; `bowl` is the centre scoop; `dot` sits below the
  /// bowl (lower-centre). Unknown → null (inert).
  static Alignment? _zoneAlignment(String? zone) => switch (zone) {
        'dot' => const Alignment(0.0, 0.60),
        'bowl' => const Alignment(0.0, 0.12),
        'start' => const Alignment(0.5, -0.35),
        _ => null,
      };
}

/// Paints a soft radial scrim: transparent in the lit zone, a gentle ink dim
/// beyond it — so the whole letter stays visible while the eye is drawn to the
/// drilled part (sketch 002 Variant B `radial-gradient(... transparent 62px,
/// rgba(34,42,46,0.42) 150px)`).
class _SpotlightPainter extends CustomPainter {
  const _SpotlightPainter(this.align);

  final Alignment align;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final centre = Offset(
      rect.center.dx + align.x * rect.width / 2,
      rect.center.dy + align.y * rect.height / 2,
    );
    // Absolute radii (px): clear until ~lit, fully dimmed by ~outer. A gentle dim
    // (D-05 keeps the letter visible), never a hard mask.
    const double lit = 84;
    const double outer = 190;
    final shader = ui.Gradient.radial(
      centre,
      outer,
      const [Color(0x00000000), Color(0x00000000), _dim],
      [0.0, lit / outer, 1.0],
    );
    canvas.drawRect(rect, Paint()..shader = shader);
  }

  // The dim tone — the kit ink foreground at a soft alpha (translucent, so the
  // dimmed letter is still legible). Matches the sketch's rgba(34,42,46,~0.34).
  static const Color _dim = Color(0x57222A2E); // QalamTokens.fg @ ~0.34

  @override
  bool shouldRepaint(covariant _SpotlightPainter oldDelegate) =>
      oldDelegate.align != align;
}
