// ArabicText — THE signature RTL content widget. Every Arabic string in the app
// renders through it, so it bundles three concerns once, correctly:
//
//   1. Directionality(rtl) — the ONLY RTL island; the app chrome stays LTR (D-05).
//   2. Noto Naskh / Cairo style with letterSpacing:0 — never break joining (Pitfall 2).
//   3. Western digits (0–9) isolated LTR via LRI(U+2066)…PDI(U+2069) so they read
//      left-to-right inside the RTL run, and Eastern-Arabic digits are NEVER
//      produced (D-06). We never format digits via the intl locale-number path
//      on `ar` — that is the only route that injects ٠١٢ and is forbidden.

import 'package:flutter/material.dart';

import '../theme/text_styles.dart';

/// Unicode directional isolates (the modern, leak-free pair).
const String _lri = '\u{2066}'; // LEFT-TO-RIGHT ISOLATE
const String _pdi = '\u{2069}'; // POP DIRECTIONAL ISOLATE

/// Matches one or more consecutive Western digits (U+0030–U+0039).
final RegExp _digitRun = RegExp(r'[0-9]+');

/// Wrap every Western-digit run in LRI…PDI so it stays LTR inside RTL text.
String isolateDigits(String input) {
  return input.replaceAllMapped(
    _digitRun,
    (m) => '$_lri${m[0]}$_pdi',
  );
}

/// Renders a single Arabic string as an RTL island with correct shaping and
/// LTR-isolated Western numerals. Exactly one [Text] is produced.
class ArabicText extends StatelessWidget {
  const ArabicText(
    this.text, {
    super.key,
    this.style,
    this.display = false,
    this.tashkeel = false,
    this.textAlign,
    this.tabularFigures = false,
  });

  /// The Arabic string to render. Digits inside it are isolated automatically.
  final String text;

  /// Optional style override; defaults to the Arabic body (or display) role.
  final TextStyle? style;

  /// Use the 96px Cairo display role instead of the 26px Noto Naskh body role.
  final bool display;

  /// Apply the tashkeel line-height (2.0) for fully-vocalized content.
  final bool tashkeel;

  /// Alignment within the RTL island (defaults to start = right edge).
  final TextAlign? textAlign;

  /// Column-align digits with tabular figures (e.g. counters); off by default.
  final bool tabularFigures;

  @override
  Widget build(BuildContext context) {
    TextStyle base = style ??
        (display ? QalamTextStyles.arDisplay : QalamTextStyles.arBody);

    if (tashkeel) {
      base = base.copyWith(height: 2.0);
    }
    if (tabularFigures) {
      base = base.copyWith(
        fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
      );
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Text(
        isolateDigits(text),
        style: base,
        textAlign: textAlign,
      ),
    );
  }
}
