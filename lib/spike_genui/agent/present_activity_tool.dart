// THROWAWAY SPIKE — Phase 11 GenUI/native-canvas kill-shot (Plan 11-02, Task 1).
//
// PURPOSE: defines the ONE GenUI tool the spike exposes (D-11) — `present_activity` —
// as a schema fragment + a system-prompt fragment. This is the seam Phase 14's GATE
// turns on (it prototypes the TUTOR-05 present_activity hand-off): when the model
// decides the child should trace a letter, it emits a `present_activity` component
// carrying one short coaching line + the letterId, and GenUI renders that component
// by hosting the REAL native StrokeCanvas under it (see stroke_canvas_item.dart).
//
// RESEARCH correction (recorded in 11-RESEARCH): present_activity is a GenUI
// *CatalogItem selected via A2UI* — NOT a firebase_ai FunctionDeclaration. The model
// chooses it the same way it chooses a Text or Column component; the catalog schema
// (built from these fields) is what tells the model the tool exists.
//
// SECURITY (T-11-03): the only payload that ever crosses the network for this tool is
// the model-authored `coachingLine` text + a hardcoded `letterId` ("baa"). No
// List<Offset> strokes, no nickname/name/PII — the per-stroke pointer->paint loop
// stays entirely local (D-07).
//
// This file imports durable code only transitively (none directly); it modifies no
// durable file. The SC-4 git-diff guard (test/spike_genui/durable_layers_unchanged_test.dart)
// proves the sacred paths stay untouched for the whole spike.

import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

/// The GenUI component name the model emits to ask the child to trace a letter.
///
/// Exactly one tool is exposed in this spike (D-11). Keeping the literal in one
/// place means the catalog item, the schema, and the prompt fragment can never
/// drift apart.
const String kPresentActivityComponent = 'present_activity';

/// The default (and only) letter the spike traces — baa, whose signed-off
/// reference strokes live in the read-only fixture (baaReferenceStrokes).
const String kSpikeLetterId = 'baa';

/// The data schema for the `present_activity` component.
///
/// Two required fields:
///   * `coachingLine` — ONE short model-generated coaching sentence rendered ABOVE
///     the canvas (D-04, the one genuinely model-generated line in the mixed tree).
///     Declared as a `stringReference` so the model may bind it from the data model
///     or emit a literal — the genui 0.9.2 data-binding form (BoundString consumes it).
///   * `letterId` — which letter to trace. The spike pins this to "baa"; it is in the
///     schema so the present_activity seam is shaped like the real TUTOR-05 hand-off.
///
/// NOTE: the `component` discriminator is injected automatically by CatalogItem from
/// its [name], so it is intentionally NOT declared here.
///
/// Returns a [Schema] (the static type of `S.object`, which the CatalogItem
/// `dataSchema` parameter consumes directly — genui re-wraps it as an
/// [ObjectSchema] internally via `CatalogItem.dataSchema`).
Schema presentActivitySchema() {
  return S.object(
    description:
        'Asks the child to trace a single Arabic letter by hand. Renders one '
        'short coaching line above the real native tracing canvas.',
    properties: <String, Schema>{
      'coachingLine': A2uiSchemas.stringReference(
        description:
            'ONE short, warm, specific coaching sentence pitched to a 5-10 year '
            'old (e.g. "Trace the baa slowly — keep the boat nice and round."). '
            'Never generic ("try again"); name the shape.',
      ),
      'letterId': S.string(
        description:
            'The id of the letter to trace. For this spike always "baa".',
        enumValues: <String>[kSpikeLetterId],
      ),
    },
    required: <String>['coachingLine', 'letterId'],
  );
}

/// The system-prompt fragment that teaches the model WHEN/HOW to call the tool.
///
/// Joined into the PromptBuilder system prompt by gemini_transport.dart so the
/// model knows the present_activity component exists and what to put in it.
const String presentActivitySystemPromptFragment = '''
You are a warm, calm, specific Arabic handwriting tutor for a young child.
When the child should trace a letter, emit a `$kPresentActivityComponent` component
with exactly ONE short coaching line and the letterId "$kSpikeLetterId". The coaching
line must name the exact shape to aim for (e.g. the curve of the baa's boat), never a
generic "try again". Do not ask for or reference any stroke data, name, or other
personal detail — only the coaching line and the letterId.''';
