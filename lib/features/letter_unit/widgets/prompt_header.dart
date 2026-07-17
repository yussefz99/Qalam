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
import 'copy_stimulus.dart';

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
    this.listenLabel = 'Listen',
  });

  /// The full ordered part list (the `say` part is skipped automatically).
  final List<PromptPart> parts;

  /// Tapped when an audio part's play affordance is pressed (the real audio
  /// wiring is the section screen's concern, 07-05). The hero audio card also
  /// invokes this ONCE on mount to auto-play the clip (D-07).
  final void Function(String audioId)? onAudioTap;

  /// Label on the SMALL audio play button — the normal `_AudioPart` variant used
  /// when the audio sits ALONGSIDE other prompt parts (e.g. the meet teachCard's
  /// "Hear"). The call site passes the l10n `promptPlay` string. Superseded by
  /// [listenLabel] on the hero audio card (D-07) when audio is the lone stimulus.
  final String playLabel;

  /// Label on the HERO audio stimulus card (UI-SPEC §2, D-07) — the large
  /// auto-playing "sound to write" card shown when the audio is the LONE visual
  /// stimulus (listen-and-write). Defaults to the English "Listen"; the l10n
  /// `promptAudioListen` key mirrors it.
  final String listenLabel;

  /// The visual parts only — `say` excluded (components.js `visuals` filter).
  List<PromptPart> get _visuals =>
      parts.where((p) => p is! SayPart).toList(growable: false);

  @override
  Widget build(BuildContext context) {
    final visuals = _visuals;
    // Empty header collapses (components.css `.prompt-header.empty{display:none}`).
    if (visuals.isEmpty) return const SizedBox.shrink();

    // A LONE stimulus picture (the [say, image] picture-prompt exercises —
    // writeLetter.fromPicture / writeWord.picture / buildSentence.picture) is
    // rendered on its OWN here so it claims the full header width and sizes
    // RESPONSIVELY (UAT T2). The general Row path below caps a non-flex part to
    // its own footprint AND wraps the row in an IntrinsicHeight (which cannot host
    // a LayoutBuilder), so a lone image there would read as a small fixed island
    // in a wide column. The child reads the question FROM the picture — it must be
    // big and readable.
    if (visuals.length == 1 && visuals.first is ImagePart) {
      final img = visuals.first as ImagePart;
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: _ImagePart(
          imageId: img.imageId,
          caption: img.caption,
          responsive: true,
        ),
      );
    }

    // A LONE audio part (the listen-and-write shape — [say, audio]) is the "sound
    // to write" (D-07/QP-05): it renders as the HERO audio card filling the
    // stimulus zone (auto-plays once on mount, replays on tap, silent-degrades on
    // a missing clip). Audio that appears ALONGSIDE other parts (e.g. the meet
    // teachCard's audio + image + forms) stays the small "Hear"/"Play" button via
    // the general Row path below — so the hero treatment is scoped to the case
    // where the sound IS the stimulus.
    if (visuals.length == 1 && visuals.first is AudioPart) {
      final audio = visuals.first as AudioPart;
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: _AudioPart(
          key: const Key('audioCard'),
          audioId: audio.audioId,
          label: listenLabel,
          onTap: onAudioTap,
          hero: true,
        ),
      );
    }

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

// ── audio (.pp-audio teal play button + the D-07 hero stimulus card) ─────────

/// The audio affordance — two variants (UI-SPEC §2, D-07):
///
///   • NORMAL (`hero: false`) — the small teal play button, components.css
///     `.pp-audio` (ink-teal fill, white text, the sticker bottom-shadow,
///     radius 16, min-height 64). Used when audio sits ALONGSIDE other parts
///     (e.g. the meet teachCard "Hear"): a supplemental "hear it" control.
///
///   • HERO (`hero: true`) — the large "sound to write" stimulus card that fills
///     the stimulus zone for listen-and-write (ink-teal fill, white 40px speaker
///     + "Listen", radius 28, min-height 96, padding 24). It AUTO-PLAYS the clip
///     ONCE on mount (mirrors the scaffold auto-speak) and replays on tap. When
///     no clip/handler is wired it STILL renders and the tap silent-degrades to
///     the TTS say-line seam — no error surface, no broken-audio icon (mirrors
///     the `_ImagePart` errorBuilder posture; T-19-07).
class _AudioPart extends StatefulWidget {
  const _AudioPart({
    super.key,
    required this.audioId,
    required this.label,
    this.onTap,
    this.hero = false,
  });

  final String audioId;
  final String label;
  final void Function(String audioId)? onTap;

  /// The large "sound to write" stimulus card (D-07) vs the small play button.
  final bool hero;

  @override
  State<_AudioPart> createState() => _AudioPartState();
}

class _AudioPartState extends State<_AudioPart> {
  /// Guards the mount-time auto-play so the hero card plays exactly once.
  bool _autoPlayed = false;

  @override
  void initState() {
    super.initState();
    if (widget.hero) {
      // D-07: auto-play the clip ONCE on mount (the scaffold initState
      // auto-speak precedent). Fires the existing audio seam; a null handler /
      // missing clip silent-degrades to a no-op (the card still renders).
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _autoPlayed) return;
        _autoPlayed = true;
        widget.onTap?.call(widget.audioId);
      });
    }
  }

  @override
  Widget build(BuildContext context) =>
      widget.hero ? _heroCard() : _playButton();

  /// The small teal play button (`.pp-audio`) — unchanged from Plan 07-04.
  Widget _playButton() {
    return Semantics(
      button: true,
      label: widget.label,
      child: Material(
        color: QalamTokens.inkTeal, // .pp-audio background:var(--ink-teal)
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: widget.onTap == null
              ? null
              : () => widget.onTap!(widget.audioId),
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
                  widget.label,
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

  /// The hero "sound to write" stimulus card (D-07) — radius 28, min-height 96,
  /// white 40px speaker + "Listen", sticker shadow. Tokens only; no gold.
  Widget _heroCard() {
    return Semantics(
      button: true,
      label: 'Listen to the word, then write it',
      child: Material(
        color: QalamTokens.inkTeal, // --ink-teal fill (the "sound to write")
        borderRadius: BorderRadius.circular(QalamTokens.radiusXl), // 28
        child: InkWell(
          borderRadius: BorderRadius.circular(QalamTokens.radiusXl),
          onTap: () => widget.onTap?.call(widget.audioId), // replay any time
          child: Container(
            constraints: const BoxConstraints(minHeight: 96), // --target-large
            padding: const EdgeInsets.all(24), // space-6
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(QalamTokens.radiusXl),
              boxShadow: const [
                // sticker shadow 0 4px 0 --deep-ink.
                BoxShadow(color: QalamTokens.deepInk, offset: Offset(0, 4)),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.volume_up_rounded,
                    color: QalamTokens.fgOnPrimary, size: 40),
                const SizedBox(width: 12), // icon↔label gap (space-3)
                Text(
                  widget.label,
                  style: QalamTextStyles.button.copyWith(
                    color: QalamTokens.fgOnPrimary,
                    fontSize: 20, // UI-SPEC audio-card label 20px
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

/// Responsive stimulus sizing (UAT T2): a LONE picture prompt grows to a readable
/// fraction of the available header width, clamped to a sane min/max, at the
/// ~260:176 aspect the art was authored for. This REPLACES the old fixed 260x176
/// pixel box, which read as a small island in a wide tablet column no matter how
/// large the constant was set.
const double _kStimulusWidthFraction = 0.6;
const double _kStimulusMinWidth = 220;
const double _kStimulusMaxWidth = 560;
const double _kStimulusAspect = 260 / 176; // ≈ 1.48

/// The picture card — components.css `.pp-img` (an aqua box, radius 14) with an
/// optional caption beneath (.pp-cap). Renders the REAL illustration when its
/// `imageId` resolves to a bundled `assets/images/` asset (quick task 260615-tqu,
/// wiring the baa unit's door/duck/big-door art); otherwise it falls back to the
/// original hatched stub — the imageId shown as a Text chip inside the box.
///
/// SIZING: when [responsive] (the lone picture-prompt path) the box sizes to a
/// fraction of the available header width via a [LayoutBuilder] + [AspectRatio] —
/// big on a wide tablet column, shrinking to fit a narrow one (UAT T2). When NOT
/// [responsive] (a thumbnail alongside other prompt parts, e.g. the teachCard.meet
/// row) it keeps a compact fixed footprint — and stays free of [LayoutBuilder] so
/// it survives that row's [IntrinsicHeight] (which cannot query a LayoutBuilder's
/// intrinsic dimensions).
///
/// SILENT-DEGRADE (mirrors the audio seam's never-block posture): an unmapped
/// imageId resolves to null → the hatched stub; and a mapped-but-unloadable file
/// hits `Image.asset`'s errorBuilder, which reuses the SAME stub. Either way a
/// missing image never throws and never blocks the trace loop.
class _ImagePart extends StatelessWidget {
  const _ImagePart({
    required this.imageId,
    this.caption,
    this.responsive = false,
  });

  final String imageId;
  final String? caption;

  /// Size the stimulus responsively to the available header width (the lone
  /// picture-prompt path) instead of a fixed pixel box.
  final bool responsive;

  @override
  Widget build(BuildContext context) {
    // Pure static resolution — the leaf widget needs no Riverpod wiring (the
    // provider exists for future Consumer call sites). Null → render the stub.
    final String? assetPath = AssetImageResolver.imageAssetFor(imageId);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        responsive ? _responsiveBox(assetPath) : _fixedBox(assetPath),
        if (caption != null && caption!.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            caption!,
            textAlign: TextAlign.center,
            // UAT T2 (mirrors feedback_panel_v2.dart's idle-hint fix): a pure-
            // English caption ("what does it start with?") under the exercise's
            // ambient RTL Directionality has its trailing "?" bidi-resolved toward
            // the RTL embedding direction (it jumps to the front). Pin LTR so the
            // punctuation stays at the end. The source caption string is unchanged.
            textDirection: TextDirection.ltr,
            style: QalamTextStyles.label
                .copyWith(fontSize: 15, color: QalamTokens.fgMuted),
          ),
        ],
      ],
    );
  }

  /// The responsive stimulus box: a fraction of the available header width
  /// (clamped), at the authored aspect. Grows on a wide tablet column, shrinks to
  /// fit a narrow one, never overflows.
  Widget _responsiveBox(String? assetPath) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double available = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : _kStimulusMaxWidth; // defensive: an unbounded parent → the max cap.
        double boxWidth = (available * _kStimulusWidthFraction)
            .clamp(_kStimulusMinWidth, _kStimulusMaxWidth);
        // Never overflow a column narrower than the readable minimum.
        if (boxWidth > available) boxWidth = available;
        return SizedBox(
          width: boxWidth,
          child: AspectRatio(
            aspectRatio: _kStimulusAspect,
            child: _decoratedBox(assetPath),
          ),
        );
      },
    );
  }

  /// The compact fixed footprint for a thumbnail alongside other prompt parts
  /// (the teachCard.meet row). No LayoutBuilder — safe under the row's
  /// IntrinsicHeight. Keeps the ~260:176 authored aspect.
  Widget _fixedBox(String? assetPath) => SizedBox(
        width: 260,
        height: 176,
        child: _decoratedBox(assetPath),
      );

  /// The aqua card (radius 14) that fills whatever tight box it is given, showing
  /// the real illustration (clipped, cover) or the hatched stub. Shared by both
  /// sizing paths so the silent-degrade posture is identical in each.
  Widget _decoratedBox(String? assetPath) => Container(
        decoration: BoxDecoration(
          color: QalamTokens.softAqua,
          borderRadius: BorderRadius.circular(14), // .pp-img radius 14
          border: Border.all(color: QalamTokens.aquaEdge),
        ),
        alignment: Alignment.center,
        // The real illustration when resolvable; the hatched imageId stub
        // otherwise. The Image is clipped to the radius-14 box and falls back to
        // the SAME stub if the asset fails to load (silent degrade).
        child: assetPath == null
            ? _hatchedStub()
            : ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.asset(
                  assetPath,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stack) => _hatchedStub(),
                ),
              ),
      );

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
    // D-05 (19-03): a copy word (`reveal:"thenHide"`) is now the child-controlled
    // [CopyStimulus] (reveal → hide → peek), REPLACING the old static
    // `opacity 0.18` dim. Nothing hides on a timer — every reveal/hide is a
    // child action, so recall stays honest.
    if (part.reveal == 'thenHide') {
      return CopyStimulus(word: part.text);
    }

    final double gap = part.loose ? 24 : 14; // .pp-text gap / .loose gap:24
    // A slot exercise (completeWord/fillBlank) shows the word at the full 40px
    // stimulus size (UI-SPEC Display role) so the highlighted gap reads as part
    // of a real word; other prompt text keeps the 34px prompt Arabic role.
    final double glyphSize = part.gaps.isNotEmpty ? 40 : 34;

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
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Wrap(
          spacing: gap,
          runSpacing: 6,
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: _tokens(glyphSize),
        ),
      ),
    );
  }

  /// Splits the authored text on the `__blank__` / `_letter_` markers and renders
  /// each run: plain Arabic via [ArabicText] at [glyphSize], a marker as its big
  /// highlighted slot box (D-06). The literal marker NEVER reaches the screen
  /// (Pitfall 6) — the split retires it before render.
  List<Widget> _tokens(double glyphSize) {
    final widgets = <Widget>[];
    // Split keeping the markers (components.js replaces them inline).
    final pattern = RegExp(r'(__blank__|_letter_)');
    final raw = part.text;
    int last = 0;
    for (final m in pattern.allMatches(raw)) {
      if (m.start > last) {
        final chunk = raw.substring(last, m.start).trim();
        if (chunk.isNotEmpty) widgets.add(_arabic(chunk, glyphSize));
      }
      widgets.add(m.group(0) == '__blank__'
          ? const _GapWord()
          : const _GapLetter());
      last = m.end;
    }
    if (last < raw.length) {
      final chunk = raw.substring(last).trim();
      if (chunk.isNotEmpty) widgets.add(_arabic(chunk, glyphSize));
    }
    if (widgets.isEmpty) widgets.add(_arabic(raw, glyphSize));
    return widgets;
  }

  Widget _arabic(String text, double fontSize) => ArabicText(
        text,
        // .pp-text deep-ink prompt Arabic role (34px prompt / 40px slot word).
        style: QalamTextStyles.arBody.copyWith(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          color: QalamTokens.deepInk,
        ),
      );
}

/// The big highlighted missing-WORD slot box (D-06/QP-04, UI-SPEC §3): radius
/// 14, 2px ink-teal outline, a gentle teal wash to draw the eye (no gold),
/// min-width 72 / min-height 64 to match the 40px slot-word line. RTL-placed at
/// the gap's reading position by the parent [Wrap]. `Key('gapSlot')` keys it for
/// the D-06 contract. (The continuous "pulse" in the UI-SPEC is rendered as a
/// strong static highlight — a repeating ticker would hang the many
/// `pumpAndSettle` widget tests that drive real completeWord/fillBlank nodes.)
class _GapWord extends StatelessWidget {
  const _GapWord();
  @override
  Widget build(BuildContext context) => Container(
        key: const Key('gapSlot'),
        constraints: const BoxConstraints(minWidth: 72, minHeight: 64),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          // gentle teal wash so the eye lands on the gap (mirrors the given-ink
          // blank cell's inkTeal-alpha fill; NOT gold).
          color: QalamTokens.inkTeal.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14), // --radius-md
          border: Border.all(color: QalamTokens.inkTeal, width: 2),
        ),
        child: const Icon(Icons.crop_square_rounded,
            color: QalamTokens.inkTeal, size: 22),
      );
}

/// The big highlighted missing-LETTER slot box (D-06/QP-04, UI-SPEC §3): radius
/// 14, 2px ink-teal outline, teal wash, min-width 56 / min-height 64. Keyed
/// `gapSlot` for the D-06 contract.
class _GapLetter extends StatelessWidget {
  const _GapLetter();
  @override
  Widget build(BuildContext context) => Container(
        key: const Key('gapSlot'),
        constraints: const BoxConstraints(minWidth: 56, minHeight: 64),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: QalamTokens.inkTeal.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: QalamTokens.inkTeal, width: 2),
        ),
        child: const Icon(Icons.circle_outlined,
            color: QalamTokens.inkTeal, size: 20),
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
