// PromptHeader — the COMPOSITION ENGINE of the Letter-Unit exercise system
// (Plan 07-04). Renders an ORDERED list of [PromptPart]s into the header row,
// 1:1 with the prototype `components.js renderPart` / `components.css .ppart-*`.
//
// SOURCE (reproduce exactly):
//   docs/design/prototypes/letter-unit-baa/prototype/exercise-components/
//     components.js   (PromptHeader / renderPart / renderText)
//     components.css  (.prompt-header / .ppart / .pp-audio / .pp-img / .pp-text /
//                      .pp-rule + the gap-word/gap-letter markers)
//   docs/design/prototypes/letter-unit-baa/COMPONENTS.md §2 (the part kinds).
//
// THE KEY RULE (components.js line 21-24): the `say` part is PULLED OUT of the
// header row — it belongs in the mascot's speech bubble, not here. PromptHeader
// exposes it via [sayLine] so [ExerciseScaffold] can place it in the bubble. The
// header itself renders only the visual parts (audio/image/text/rule/forms); if
// there are none, the header COLLAPSES (the prototype's `.empty` → display:none).
//
// A new question type = a new list of PromptParts fed here — never new UI.

import 'package:flutter/material.dart';

import '../../../models/exercise.dart';
import '../../../services/asset_image_resolver.dart';
import '../../../theme/qalam_tokens.dart';
import '../../../theme/text_styles.dart';
import '../../../widgets/arabic_text.dart';

/// The `say` part, extracted from a [PromptPart] list. The header never renders
/// it (components.js); the scaffold puts it in the speech bubble.
String promptSayLine(List<PromptPart> parts) {
  for (final p in parts) {
    if (p is SayPart) return p.line;
  }
  return '';
}

/// Renders the ordered visual prompt parts (everything except `say`).
///
/// Pixel-faithful to `components.css .prompt-header` (a left-to-right row of
/// stretch-height part cards, gap 12). RTL-safe: Arabic content renders through
/// [ArabicText] (its own RTL island); the row layout itself is direction-neutral
/// stretch. An empty visual list renders nothing (the prototype's `.empty`).
class PromptHeader extends StatelessWidget {
  const PromptHeader({
    super.key,
    required this.parts,
    this.onAudioTap,
    this.playLabel = 'Play',
  });

  /// The full ordered part list (the `say` part is skipped automatically).
  final List<PromptPart> parts;

  /// Tapped when an audio part's teal play button is pressed (visual ping in the
  /// prototype; the real audio wiring is the section screen's concern, 07-05).
  final void Function(String audioId)? onAudioTap;

  /// Label on the audio play button. Defaults to a plain English fallback; the
  /// call site passes the l10n `promptPlay` string.
  final String playLabel;

  /// The visual parts only — `say` excluded (components.js `visuals` filter).
  List<PromptPart> get _visuals =>
      parts.where((p) => p is! SayPart).toList(growable: false);

  @override
  Widget build(BuildContext context) {
    final visuals = _visuals;
    // Empty header collapses (components.css `.prompt-header.empty{display:none}`).
    if (visuals.isEmpty) return const SizedBox.shrink();

    return Padding(
      // components.css `.prompt-header{margin-top:12px;…}`
      padding: const EdgeInsets.only(top: 12),
      // IntrinsicHeight resolves the prototype's `align-items:stretch` (equal
      // card heights) under an unbounded-height Column without forcing infinity.
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < visuals.length; i++) ...[
              if (i > 0) const SizedBox(width: 12), // .prompt-header gap:12
              _partFlex(visuals[i]),
            ],
          ],
        ),
      ),
    );
  }

  /// `text` parts flex to fill (.ppart-text{flex:1}); the rest size to content
  /// (.ppart-image{flex:0 0 auto}), matching components.css.
  Widget _partFlex(PromptPart part) {
    final child = _renderPart(part);
    if (part is TextPart) return Expanded(child: child);
    return child;
  }

  Widget _renderPart(PromptPart part) {
    return switch (part) {
      AudioPart() => _AudioPart(
          audioId: part.audioId,
          label: playLabel,
          onTap: onAudioTap,
        ),
      ImagePart() => _ImagePart(imageId: part.imageId, caption: part.caption),
      TextPart() => _TextPart(part: part),
      RulePart() => _RulePart(label: part.label),
      FormsPart() => FourFormsStrip(char: part.char, forms: part.forms),
      // say is filtered out above; unknown kinds render nothing (defensive).
      _ => const SizedBox.shrink(),
    };
  }
}

// ── audio (.pp-audio teal play button) ───────────────────────────────────────

/// The teal play button — components.css `.pp-audio` (ink-teal fill, white text,
/// the sticker bottom-shadow, radius 16, min-height 64 = the kids-UX target).
class _AudioPart extends StatelessWidget {
  const _AudioPart({required this.audioId, required this.label, this.onTap});

  final String audioId;
  final String label;
  final void Function(String audioId)? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: QalamTokens.inkTeal, // .pp-audio background:var(--ink-teal)
        borderRadius: BorderRadius.circular(16),
        // .pp-audio box-shadow:0 4px 0 var(--deep-ink) (the sticker shadow)
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap == null ? null : () => onTap!(audioId),
          child: Container(
            constraints: const BoxConstraints(minHeight: 64), // target-min
            padding: const EdgeInsets.symmetric(horizontal: 22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(color: QalamTokens.deepInk, offset: Offset(0, 4)),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.volume_up_rounded,
                    color: QalamTokens.fgOnPrimary, size: 24),
                const SizedBox(width: 12), // .pp-audio gap:12
                Text(
                  label,
                  style: QalamTextStyles.button.copyWith(
                    color: QalamTokens.fgOnPrimary,
                    fontSize: 18, // .pp-audio font-size:18px
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

// ── image (.pp-img hatched stub + caption) ───────────────────────────────────

/// The picture card — components.css `.pp-img` (a 128×84 aqua box, radius 14)
/// with an optional caption beneath (.pp-cap). Renders the REAL illustration
/// when its `imageId` resolves to a bundled `assets/images/` asset
/// (quick task 260615-tqu, wiring the baa unit's door/duck/big-door art);
/// otherwise it falls back to the original hatched stub — the imageId shown as a
/// Text chip inside the box.
///
/// SILENT-DEGRADE (mirrors the audio seam's never-block posture): an unmapped
/// imageId resolves to null → the hatched stub; and a mapped-but-unloadable file
/// hits `Image.asset`'s errorBuilder, which reuses the SAME stub. Either way a
/// missing image never throws and never blocks the trace loop.
class _ImagePart extends StatelessWidget {
  const _ImagePart({required this.imageId, this.caption});

  final String imageId;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    // Pure static resolution — the leaf widget needs no Riverpod wiring (the
    // provider exists for future Consumer call sites). Null → render the stub.
    final String? assetPath = AssetImageResolver.imageAssetFor(imageId);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 128, // .pp-img width:128px
          height: 84, // .pp-img height:84px
          decoration: BoxDecoration(
            color: QalamTokens.softAqua,
            borderRadius: BorderRadius.circular(14), // .pp-img radius 14
            border: Border.all(color: QalamTokens.aquaEdge),
          ),
          alignment: Alignment.center,
          // The real illustration when resolvable; the hatched imageId stub
          // otherwise. The Image is clipped to the radius-14 box and falls back
          // to the SAME stub if the asset fails to load (silent degrade).
          child: assetPath == null
              ? _hatchedStub()
              : ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.asset(
                    assetPath,
                    width: 128,
                    height: 84,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stack) => _hatchedStub(),
                  ),
                ),
        ),
        if (caption != null && caption!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            caption!,
            textAlign: TextAlign.center,
            style: QalamTextStyles.label
                .copyWith(fontSize: 11, color: QalamTokens.fgMuted),
          ),
        ],
      ],
    );
  }

  /// The original hatched stub — the imageId in a raised rounded chip. Shared by
  /// BOTH the unknown-id branch and the Image.asset load-error fallback so the
  /// silent-degrade looks identical whether the id is unmapped or the file fails.
  Widget _hatchedStub() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: QalamTokens.surfaceRaised.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          imageId,
          textAlign: TextAlign.center,
          style: QalamTextStyles.label.copyWith(
            fontSize: 10,
            color: QalamTokens.fgMuted,
          ),
        ),
      );
}

// ── text (.pp-text Arabic, with __blank__ / _letter_ slot markers) ───────────

/// The Arabic prompt card — components.css `.pp-text` (a white card, radius 16,
/// min-height 64, Arabic 34px deep-ink). Renders `__blank__` → a dashed
/// missing-WORD box and `_letter_` → a dashed missing-LETTER slot, matching
/// components.js `renderText`. `loose:true` widens the inter-token gap (the
/// connect task, .pp-text.loose); `reveal:"thenHide"` dims the word (.hidden).
class _TextPart extends StatelessWidget {
  const _TextPart({required this.part});

  final TextPart part;

  @override
  Widget build(BuildContext context) {
    final double gap = part.loose ? 24 : 14; // .pp-text gap / .loose gap:24
    final bool dim = part.reveal == 'thenHide'; // .hidden-word{opacity:.18}

    return Container(
      constraints: const BoxConstraints(minHeight: 64), // target-min
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
      decoration: BoxDecoration(
        color: QalamTokens.surfaceRaised, // .pp-text background:var(--white)
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: QalamTokens.aquaEdge),
        boxShadow: const [
          BoxShadow(color: Color(0x1A0E5B5F), offset: Offset(0, 2), blurRadius: 6, spreadRadius: -2),
        ],
      ),
      child: Opacity(
        opacity: dim ? 0.18 : 1.0,
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Wrap(
            spacing: gap,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: _tokens(),
          ),
        ),
      ),
    );
  }

  /// Splits the authored text on the `__blank__` / `_letter_` markers and renders
  /// each run: plain Arabic via [ArabicText], a marker as its dashed slot.
  List<Widget> _tokens() {
    final widgets = <Widget>[];
    // Split keeping the markers (components.js replaces them inline).
    final pattern = RegExp(r'(__blank__|_letter_)');
    final raw = part.text;
    int last = 0;
    for (final m in pattern.allMatches(raw)) {
      if (m.start > last) {
        final chunk = raw.substring(last, m.start).trim();
        if (chunk.isNotEmpty) widgets.add(_arabic(chunk));
      }
      widgets.add(m.group(0) == '__blank__'
          ? const _GapWord()
          : const _GapLetter());
      last = m.end;
    }
    if (last < raw.length) {
      final chunk = raw.substring(last).trim();
      if (chunk.isNotEmpty) widgets.add(_arabic(chunk));
    }
    if (widgets.isEmpty) widgets.add(_arabic(raw));
    return widgets;
  }

  Widget _arabic(String text) => ArabicText(
        text,
        // .pp-text font-size:34px deep-ink (the prompt Arabic role).
        style: QalamTextStyles.arBody.copyWith(
          fontSize: 34,
          fontWeight: FontWeight.w600,
          color: QalamTokens.deepInk,
        ),
      );
}

/// `.pp-text .gap-word` — a dashed missing-WORD box (min 84 wide).
class _GapWord extends StatelessWidget {
  const _GapWord();
  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(minWidth: 84),
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: QalamTokens.inkTeal,
            width: 2,
            style: BorderStyle.solid, // dashed in CSS; Flutter draws a teal ring
          ),
        ),
        child: Icon(Icons.crop_square_rounded,
            color: QalamTokens.inkTeal, size: 20),
      );
}

/// `.pp-text .gap-letter` — a dashed missing-LETTER slot (42 wide).
class _GapLetter extends StatelessWidget {
  const _GapLetter();
  @override
  Widget build(BuildContext context) => Container(
        width: 42,
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: QalamTokens.inkTeal, width: 2),
        ),
        child: Icon(Icons.circle_outlined,
            color: QalamTokens.inkTeal, size: 18),
      );
}

// ── rule (.pp-rule gold instruction chip) ────────────────────────────────────

/// The grammar-rule chip — components.css `.pp-rule` (gold-tint fill, the Arabic
/// rule on top, the English label beneath). GOLD-TINT, not reward gold: this is
/// an instruction surface, anti-gamification-safe (no score, no star).
class _RulePart extends StatelessWidget {
  const _RulePart({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 64),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: QalamTokens.goldTint, // .pp-rule background:var(--gold-tint)
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEBD49A)), // .pp-rule border
      ),
      child: Center(
        child: ArabicText(
          label,
          // .pp-rule-ar font-size:24px, the brown gold-ink instruction tone.
          style: QalamTextStyles.arBody.copyWith(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF9A6A2E),
          ),
        ),
      ),
    );
  }
}

// ── forms (the teachCard four-forms strip) ───────────────────────────────────

/// The four contextual forms of a base letter (isolated/initial/medial/final),
/// shown on the Meet/teach card — COMPONENTS.md §6 `forms` part. A horizontal
/// strip of the form glyphs, each via [ArabicText] (RTL island).
///
/// Public (not `_`-private) so [ExerciseScaffold]'s teachCard custom surface can
/// reuse the same strip when `forms` is presented as a panel rather than inline.
class FourFormsStrip extends StatelessWidget {
  const FourFormsStrip({super.key, required this.char, required this.forms});

  final String char;

  /// FormName entries ("isolated"/"initial"/"medial"/"final"); each maps to its
  /// contextual glyph of [char] via [contextualGlyph].
  final List<String> forms;

  /// The contextual glyph of [base] for a FormName — baa shown by name; falls
  /// back to the isolated glyph for an unknown form (components.js FORMS map).
  static String contextualGlyph(String base, String form) {
    // baa contextual forms (the prototype's FORMS map). Generic letters fall
    // back to the base glyph; baa is the built unit so its forms are explicit.
    if (base == 'ب') {
      return switch (form) {
        'initial' => 'بـ',
        'medial' => 'ـبـ',
        'final' => 'ـب',
        _ => 'ب',
      };
    }
    return base;
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < forms.length; i++) ...[
            if (i > 0) const SizedBox(width: 12),
            Container(
              constraints: const BoxConstraints(minHeight: 64, minWidth: 64),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: QalamTokens.surfaceRaised,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: QalamTokens.aquaEdge),
              ),
              alignment: Alignment.center,
              child: ArabicText(
                contextualGlyph(char, forms[i]),
                style: QalamTextStyles.arBody.copyWith(
                  fontSize: 34,
                  fontWeight: FontWeight.w600,
                  color: QalamTokens.deepInk,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
