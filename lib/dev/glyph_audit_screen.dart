// GlyphAuditScreen — the D-12 four-form shaping risk gate (plan 01-03).
//
// PURPOSE: prove the BUNDLED Arabic reading font (Noto Naskh Arabic) shapes
// every representative curriculum letter correctly in ALL FOUR contextual forms
// (isolated / initial / medial / final) at the child-facing 96px display size —
// no tofu, correct joining, لا forming the single ﻻ ligature, tashkeel placed at
// line-height 2.0, and Western digits 0–9 rendering LTR beside Arabic. This is
// the phase's one hard risk; a golden test (test/glyph_audit_golden_test.dart)
// locks the baseline as a regression gate, and a human visually confirms the
// FIRST baseline (Task 3 — the D-12 human-PASS).
//
// FORM-FORCING (ZWJ): Flutter's HarfBuzz shaper picks the contextual form from a
// letter's neighbors. To elicit a single positional form IN THIS HARNESS ONLY we
// surround the letter with Zero-Width Joiner (U+200D):
//   isolated 'ه'   initial 'ه‍'   medial '‍ه‍'   final '‍ه'
// ZWJ is an AUDIT-HARNESS DEVICE ONLY — it must NEVER appear in production
// strings (real shaping comes from the surrounding word). See RESEARCH
// §Glyph-Audit Method (the ZWJ table) and the "Don't Hand-Roll" note.
//
// FONT-UNDER-AUDIT (Pitfall 3 — system-fallback masking): the cells force
// fontFamily = QalamFonts.arabic (the bundled Noto Naskh) onto the 96px arDisplay
// role rather than inheriting Cairo, so the font actually under audit is the
// Arabic READING/tracing-content font. To prove the bundled TTF (not an OS
// fallback) is the one shaping, temporarily swap _auditFontFamily to an
// obviously-distinct family and confirm the glyphs change — see the swap-test
// note below. If Noto Naskh genuinely mis-shapes any curriculum form, switch the
// bundled Arabic font to Amiri (the documented fallback) and regenerate.
//
// This screen is a DEBUG SEAM reachable only via the dev route /dev/glyph-audit
// (see lib/router/app_router.dart). It is NOT surfaced in user-facing nav.

import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/dimens.dart';
import '../theme/text_styles.dart';

/// Zero-width joiner (U+200D) — forces contextual joining forms in the harness.
/// AUDIT-HARNESS ONLY; never place this in production strings.
const String _zwj = '‍';

/// The font family actually under audit. This is the BUNDLED Noto Naskh Arabic
/// (the Arabic reading/tracing-content font). SWAP-TEST (Pitfall 3): set this to
/// an obviously-distinct family (e.g. 'Cairo' or a non-existent name) and re-run
/// — if the glyphs visibly change, you have proven the bundled TTF, not an OS
/// fallback, is the one shaping these cells. Restore to QalamFonts.arabic after.
const String _auditFontFamily = QalamFonts.arabic;

/// Representative tricky-joiner set (RESEARCH §Glyph-Audit "Representative letter
/// set"). Each entry exercises a hard shaping case; grouped letters share a
/// shaping class and are all rendered so dot-bearing variants are inspectable.
const List<String> _auditLetters = <String>[
  'ه', // haa — famously divergent four forms; the #1 shaping smoke test
  'ع', 'غ', // ain / ghain — complex medial form
  'ك', // kaaf — distinct initial/medial vs isolated/final
  'ل', // laam — tall joiner; sets up the lam-alef ligature
  'ب', 'ت', 'ث', // baa family — tooth + dot positioning across forms
  'ج', 'ح', 'خ', // jiim family — descender + medial nub
  'س', 'ش', // siin / shiin — three-tooth shaping, easy to mis-join
  'م', // miim — loop + descender, medial form
  'ي', // yaa — final-form tail + dots
];

/// The mandatory lam-alef ligature: must render as the single glyph ﻻ, NOT as
/// ل + ا side by side. Shown across its forms (final/medial use ZWJ).
const String _lamAlef = 'لا';

/// A fully-vocalized tashkeel sample (RESEARCH: "any letter + tashkeel"). Renders
/// at line-height 2.0 so diacritic stacking/clipping is inspectable (D-04).
const String _tashkeelSample = 'بَ بِ بُ بّ';

/// Mixed Arabic + Western digits — must render 0–9 in correct LTR order beside
/// the Arabic (D-06). Digits are isolated LTR via LRI(U+2066)…PDI(U+2069); the
/// surrounding text stays RTL.
const String _lri = '\u{2066}'; // LEFT-TO-RIGHT ISOLATE
const String _pdi = '\u{2069}'; // POP DIRECTIONAL ISOLATE
const String _mixedDigitSample = 'سنة ${_lri}0123456789$_pdi مثال';

class GlyphAuditScreen extends StatelessWidget {
  const GlyphAuditScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // The 96px arDisplay role, but forced onto the bundled Noto Naskh Arabic so
    // the Arabic reading font is the one under audit (not Cairo).
    final TextStyle cell = QalamTextStyles.arDisplay.copyWith(
      fontFamily: _auditFontFamily,
    );

    return Scaffold(
      backgroundColor: QalamColors.bg,
      appBar: AppBar(
        backgroundColor: QalamColors.bg,
        title: Text('Glyph Audit (D-12)', style: QalamTextStyles.heading),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(QalamSpace.space6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const _SectionLabel('Four contextual forms (ZWJ-forced)'),
              const _AuditHeaderRow(),
              for (final String letter in _auditLetters)
                _AuditLetterRow(letter: letter, style: cell),

              const SizedBox(height: QalamSpace.space6),
              const _SectionLabel('Lam-alef ligature — must form a single ﻻ'),
              _AuditLetterRow(letter: _lamAlef, style: cell),

              const SizedBox(height: QalamSpace.space6),
              const _SectionLabel('Tashkeel placement (line-height 2.0)'),
              _AuditTashkeelRow(style: cell),

              const SizedBox(height: QalamSpace.space6),
              const _SectionLabel('Mixed Arabic + Western digits (0–9 LTR)'),
              _AuditMixedDigitRow(style: cell),
            ],
          ),
        ),
      ),
    );
  }
}

/// A small muted section heading between audit blocks.
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: QalamSpace.space3),
        child: Text(text, style: QalamTextStyles.label),
      );
}

class _AuditHeaderRow extends StatelessWidget {
  const _AuditHeaderRow();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(bottom: QalamSpace.space4),
      child: Row(
        children: <Widget>[
          _HeaderLabel('isolated'),
          _HeaderLabel('initial'),
          _HeaderLabel('medial'),
          _HeaderLabel('final'),
        ],
      ),
    );
  }
}

class _HeaderLabel extends StatelessWidget {
  const _HeaderLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) =>
      Expanded(child: Text(label, style: QalamTextStyles.label));
}

/// One row: the four ZWJ-forced contextual forms of [letter] at 96px.
class _AuditLetterRow extends StatelessWidget {
  const _AuditLetterRow({required this.letter, required this.style});
  final String letter;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    // ZWJ on the trailing/leading side forces the requested contextual form.
    final List<String> forms = <String>[
      letter, // isolated — bare letter
      '$letter$_zwj', // initial — ZWJ after → following-join
      '$_zwj$letter$_zwj', // medial — ZWJ both sides
      '$_zwj$letter', // final — ZWJ before → preceding-join
    ];
    return Padding(
      padding: const EdgeInsets.only(bottom: QalamSpace.space2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          for (final String form in forms)
            Expanded(child: _AuditCell(text: form, style: style)),
        ],
      ),
    );
  }
}

/// Tashkeel row — rendered at line-height 2.0 to inspect diacritic stacking.
class _AuditTashkeelRow extends StatelessWidget {
  const _AuditTashkeelRow({required this.style});
  final TextStyle style;

  @override
  Widget build(BuildContext context) => _AuditCell(
        text: _tashkeelSample,
        style: style.copyWith(height: 2.0),
      );
}

/// Mixed Arabic + Western-digit row — digits must read 0–9 LTR beside Arabic.
class _AuditMixedDigitRow extends StatelessWidget {
  const _AuditMixedDigitRow({required this.style});
  final TextStyle style;

  @override
  Widget build(BuildContext context) =>
      _AuditCell(text: _mixedDigitSample, style: style);
}

/// A single audit cell: an RTL island rendering one (possibly ZWJ-forced) form.
class _AuditCell extends StatelessWidget {
  const _AuditCell({required this.text, required this.style});
  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(QalamSpace.space2),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Text(text, style: style),
      ),
    );
  }
}
