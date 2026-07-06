/// Pure Dart, no dart:ui, no Flutter imports.
///
/// THE SINGLE PER-FORM REFERENCE RESOLVER (Plan 17-03, Pitfall 7).
///
/// Canvas completion count, `computeStrokeDiff`, and the scorer must ALL resolve
/// the reference strokes for the asked positional form the SAME way — a taa
/// medial completing at 3 strokes has to agree with the scorer's expected
/// count, and the F5 form-blind verdict is fixed by threading ONE resolution
/// everywhere. This file is that one home; `write_surface._formStrokes`,
/// `computeStrokeDiff`, and `scoreLetter` all delegate here.
///
/// SECURITY: pure curriculum-data read. No child points, nothing logged.
library;

import '../../models/letter.dart';
import 'tolerances.dart';

/// Resolves the reference strokes for the asked positional [form].
///
/// Returns `letter.contextualForms[form].referenceStrokes` when [form] is
/// non-null AND that per-form stroke list is non-empty; otherwise the letter's
/// base [Letter.referenceStrokes]. A null [form], a null `contextualForms`
/// map, a missing/`null` [Form] slot, or an EMPTY per-form list ALL fall back
/// to the base reference (the authored-empty slot the RED contract pins with
/// `initial`).
List<StrokeSpec> resolveReferenceStrokes(Letter letter, String? form) {
  if (form != null) {
    final Form? f = letter.contextualForms?[form];
    if (f != null && f.referenceStrokes.isNotEmpty) {
      return f.referenceStrokes;
    }
  }
  return letter.referenceStrokes;
}

/// Resolves the scoring [Tolerances] for the asked positional [form].
///
/// Resolution order (RESEARCH Pattern 2): explicit [override] →
/// `contextualForms[form].tolerances` → [Letter.tolerances] →
/// [Tolerances.normal]. Mirrors the base-reference fall-through above so the
/// scorer reads ONE consistent per-form policy.
Tolerances resolveTolerances(
  Letter letter,
  String? form,
  Tolerances? override,
) {
  if (override != null) return override;
  if (form != null) {
    final Form? f = letter.contextualForms?[form];
    final t = f?.tolerances;
    if (t != null) return t;
  }
  return letter.tolerances ?? Tolerances.normal;
}
