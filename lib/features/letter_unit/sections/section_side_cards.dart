// Shared section side-cards + CTA buttons for the Letter-Unit sections
// (Plan 07-05). These reproduce the prototype's `.tip-card` / `.listen-card`
// side cards and the `.btn.primary` / `.btn.quiet` action buttons (unit.css),
// used by WatchTraceSection (Section 2) and FormsSection (Section 3).
//
// They are PRESENTATION ONLY — no grading, no audio logic of their own. The
// Play affordance takes an `onPlay` callback; the section wires it to the
// offline [audioPlayerProvider]. Anti-gamification: no star, no counter here.

import 'package:flutter/material.dart';

import '../../../theme/qalam_tokens.dart';
import '../../../theme/text_styles.dart';
import '../../../widgets/arabic_text.dart';

/// `.tip-card` — the gold-tint guidance card shown beside the Watch demo.
class TipCard extends StatelessWidget {
  const TipCard({super.key, required this.label, required this.body});

  final String label;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: QalamTokens.goldTint, // .tip-card background:var(--gold-tint)
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFEBD49A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label.toUpperCase(),
            style: QalamTextStyles.label.copyWith(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.12 * 10.5,
              color: const Color(0xFFB07908), // .tip-card .lbl
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: QalamTextStyles.button.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              height: 1.45,
              color: QalamTokens.fg,
            ),
          ),
        ],
      ),
    );
  }
}

/// `.listen-card` — the aqua side card with the big glyph, romanization, and an
/// offline Play button. The section owns the audio; this only renders + calls
/// back.
class ListenCard extends StatelessWidget {
  const ListenCard({
    super.key,
    required this.label,
    required this.glyph,
    required this.romanization,
    required this.playLabel,
    required this.onPlay,
    this.playKey,
    this.glyphSize = 74,
  });

  final String label;
  final String glyph;
  final String romanization;
  final String playLabel;
  final VoidCallback onPlay;
  final Key? playKey;
  final double glyphSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 210,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      decoration: BoxDecoration(
        color: QalamTokens.softAqua, // .listen-card background:var(--soft-aqua)
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: QalamTokens.aquaEdge),
        boxShadow: const [
          BoxShadow(
              color: Color(0x140E5B5F),
              offset: Offset(0, 2),
              blurRadius: 6,
              spreadRadius: -2),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              label.toUpperCase(),
              style: QalamTextStyles.label.copyWith(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.12 * 10.5,
                color: QalamTokens.fgMuted,
              ),
            ),
          ),
          const SizedBox(height: 4),
          ArabicText(
            glyph,
            style: QalamTextStyles.arDisplay.copyWith(
              fontSize: glyphSize, // .listen-card .big
              fontWeight: FontWeight.w600,
              color: QalamTokens.deepInk,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            romanization,
            style: QalamTextStyles.button.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: QalamTokens.fg,
            ),
          ),
          const SizedBox(height: 12),
          _PlayButton(key: playKey, label: playLabel, onTap: onPlay),
        ],
      ),
    );
  }
}

/// `.playbtn` — the white offline Play button inside a listen card.
class _PlayButton extends StatelessWidget {
  const _PlayButton({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: QalamTokens.surfaceRaised,
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: onTap,
          child: Container(
            height: 52, // .playbtn height:52px
            width: double.infinity,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: QalamTokens.aquaEdge),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.volume_up_rounded,
                    size: 22, color: QalamTokens.deepInk),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: QalamTextStyles.button.copyWith(
                    fontSize: 16,
                    color: QalamTokens.deepInk,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// `.btn.primary` — the teal sticker CTA (flat-bottom shadow).
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    this.onTap,
    this.iconAfter,
    this.enabled = true,
  });

  final String label;
  final VoidCallback? onTap;
  final IconData? iconAfter;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final bg = enabled ? QalamTokens.inkTeal : const Color(0xFFAFC9C9);
    final shadow = enabled ? QalamTokens.deepInk : const Color(0xFF95B4B4);
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: enabled ? onTap : null,
          child: Container(
            height: 66, // .btn height:66px
            padding: const EdgeInsets.symmetric(horizontal: 34),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              boxShadow: [BoxShadow(color: shadow, offset: const Offset(0, 5))],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: QalamTextStyles.button.copyWith(
                    fontSize: 21,
                    color: enabled
                        ? QalamTokens.fgOnPrimary
                        : QalamTokens.softAqua,
                  ),
                ),
                if (iconAfter != null) ...[
                  const SizedBox(width: 12),
                  Icon(iconAfter,
                      size: 26,
                      color: enabled
                          ? QalamTokens.fgOnPrimary
                          : QalamTokens.softAqua),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// `.btn.quiet` — the ghost CTA (transparent, aqua-edge border).
class QuietButton extends StatelessWidget {
  const QuietButton({
    super.key,
    required this.label,
    this.onTap,
    this.icon,
  });

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Container(
            height: 66,
            padding: const EdgeInsets.symmetric(horizontal: 28),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: QalamTokens.aquaEdge, width: 2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20, color: QalamTokens.fgMuted),
                  const SizedBox(width: 10),
                ],
                Text(
                  label,
                  style: QalamTextStyles.button.copyWith(
                    fontSize: 21,
                    color: QalamTokens.fgMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
