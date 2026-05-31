// GlyphAuditScreen — the D-12 four-form shaping risk gate.
//
// NOTE ON OWNERSHIP: the full audit harness + its baseline golden image are
// plan 01-03's deliverable. This file is created in plan 01-02 only because the
// already-committed golden test (test/glyph_audit_golden_test.dart) imports it;
// without the symbol the ENTIRE test suite fails to compile, which would mask
// the Wave-0 tests this plan turns green. So this is the minimal real grid that
// lets the suite compile. The golden itself stays RED until plan 01-03 lands the
// human-approved baseline (test/goldens/glyph_audit.png) — that single red is
// expected and documented.
//
// The grid forces each contextual form with the ZWJ technique (audit-harness
// ONLY — never in real strings). Rendered at the child-facing 96px display size
// with the bundled Noto Naskh Arabic font so shaping is inspectable.

import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/dimens.dart';
import '../theme/text_styles.dart';

/// Zero-width joiner — forces contextual joining forms in the audit harness.
const String _zwj = '‍';

/// Representative letters spanning the joining-behavior classes (RESEARCH table).
const List<String> _auditLetters = <String>[
  'ه', 'ع', 'ك', 'ل', 'ب', 'ج', 'س', 'م', 'ي',
];

class GlyphAuditScreen extends StatelessWidget {
  const GlyphAuditScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // The 96px Noto Naskh display style (force Noto Naskh, not Cairo, so the
    // bundled reading font is the one under audit).
    final TextStyle cell = QalamTextStyles.arDisplay.copyWith(
      fontFamily: QalamFonts.arabic,
    );

    return Scaffold(
      backgroundColor: QalamColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(QalamSpace.space6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const _AuditHeaderRow(),
              for (final String letter in _auditLetters)
                _AuditLetterRow(letter: letter, style: cell),
              // The لا ligature must form a single ﻻ glyph.
              _AuditCell(text: 'لا', style: cell),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuditHeaderRow extends StatelessWidget {
  const _AuditHeaderRow();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: QalamSpace.space4),
      child: Row(
        children: const <Widget>[
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

class _AuditLetterRow extends StatelessWidget {
  const _AuditLetterRow({required this.letter, required this.style});
  final String letter;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    // ZWJ on the leading/trailing side forces the requested contextual form.
    final forms = <String>[
      letter, // isolated
      '$letter$_zwj', // initial
      '$_zwj$letter$_zwj', // medial
      '$_zwj$letter', // final
    ];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        for (final form in forms)
          Expanded(child: _AuditCell(text: form, style: style)),
      ],
    );
  }
}

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
