// THROWAWAY SPIKE — Phase 11 GenUI/native-canvas kill-shot (Plan 11-02, Task 1).
//
// PURPOSE: THE hosting seam (D-03). Registers the REAL native StrokeCanvas as a custom
// GenUI CatalogItem named `present_activity`, embedded under a STABLE ValueKey inside a
// model-generated tree. GenUI renders one model-authored coaching line ABOVE it (D-04),
// so the rendered tree is genuinely mixed: GenUI-owned text + native real-time canvas.
//
// This is the seam Phase 14's GATE turns on. If GenUI's reactive surface rebuild
// preserves _StrokeCanvasState across rebuilds (the stable key's job — Pitfall 1), and
// the pen stays native + lag-free (Pitfall 2), the GATE can be "keep GenUI". If the
// rebuild tears the canvas State down mid-trace or an ancestor steals the stylus drag,
// THAT is the "drop GenUI" evidence. The instrumentation wrapper below makes a torn-down
// State visible (prints on initState/dispose) during the on-device A/B in Plan 03 —
// the prints live ONLY in this spike file, NEVER in durable stroke_canvas.dart.
//
// Verified against the INSTALLED genui 0.9.2 source (NOT the version-drifting docs):
//   * CatalogItem(name:, dataSchema:, widgetBuilder: (CatalogItemContext) => Widget)
//   * data accessor: `itemContext.data as JsonMap` parsed via an extension type
//     (mirrors genui's own basic_catalog_widgets/text.dart)
//   * model-bound string: A2uiSchemas.stringReference schema + BoundString(
//       dataContext: itemContext.dataContext, value: <ref>, builder: (ctx, val) {...})
//
// SECURITY (T-11-03): this widget reads only the model-authored coachingLine + letterId;
// it forwards NO scoring callbacks (D-07 — the spike judges canvas responsiveness only),
// so no List<Offset> stroke ever leaves the canvas. No durable file is edited; the SC-4
// git-diff guard proves the sacred paths stay untouched.

import 'package:flutter/material.dart';
import 'package:genui/genui.dart';

// Durable widget imported READ-ONLY — the spike hosts the REAL canvas, edits nothing.
import 'package:qalam/features/practice/widgets/stroke_canvas.dart';

import '../fixtures/baa_reference.dart';
import '../agent/present_activity_tool.dart';

/// Stable identity for the embedded canvas.
///
/// RUNTIME FINDING (Pixel Tablet emulator, 2026-06-21): a plain ValueKey did NOT
/// preserve the canvas State across GenUI's self-initiated Surface rebuilds. GenUI
/// rebuilds the surface subtree from a fresh widget, and a ValueKey only preserves
/// State among siblings of the SAME parent — so the canvas State was disposed +
/// recreated on every rebuild (Pitfall 1), even with the key correctly placed.
///
/// A GlobalKey DOES survive reparenting/rebuilds (Flutter moves the existing Element
/// + State to the new location). This is the salvage experiment: if the embedded
/// canvas State now survives GenUI's rebuilds under a GlobalKey, GenUI is keepable;
/// if DISPOSE still fires on every rebuild, that is decisive drop evidence.
final GlobalKey kEmbeddedCanvasKey = GlobalKey();

/// Typed view over the AI-generated `present_activity` component data.
///
/// Mirrors genui's own `_TextData` extension-type pattern (basic_catalog_widgets/
/// text.dart): `itemContext.data` is a `JsonMap`; `coachingLine` is a string
/// reference (literal OR data-bound — resolved by BoundString), `letterId` a literal.
extension type _PresentActivityData.fromMap(JsonMap _json) {
  /// The model-bound coaching-line reference (literal string or data-binding map).
  Object? get coachingLine => _json['coachingLine'];

  /// Which letter to trace; the spike pins this to "baa".
  String get letterId => (_json['letterId'] as String?) ?? kSpikeLetterId;
}

/// The custom CatalogItem (D-11 — the spike's only tool).
///
/// widgetBuilder returns a Column: the model-generated coaching line on top
/// (D-04), an Expanded native StrokeCanvas below under the stable key (D-03). The
/// canvas sits in a NON-scrolling Column region (Pitfall 2 — the Listener-based
/// canvas loses stylus drags inside a ScrollView ancestor).
final CatalogItem presentActivityItem = CatalogItem(
  name: kPresentActivityComponent,
  dataSchema: presentActivitySchema(),
  // The canvas needs bounded constraints (it is Expanded inside our Column); mark
  // the item implicitly flexible so a parent flex container gives it a weight.
  isImplicitlyFlexible: true,
  exampleData: <ExampleBuilderCallback>[
    () => '''
      [
        {
          "id": "root",
          "component": "$kPresentActivityComponent",
          "coachingLine": "Trace the baa slowly — keep the boat round.",
          "letterId": "$kSpikeLetterId"
        }
      ]
    ''',
  ],
  widgetBuilder: (CatalogItemContext itemContext) {
    final _PresentActivityData data = _PresentActivityData.fromMap(
      itemContext.data as JsonMap,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // D-04: the ONE model-generated line. BoundString resolves a literal OR a
        // data-model binding (the genui 0.9.2 data-binding accessor) and rebuilds
        // when it changes.
        Padding(
          padding: const EdgeInsets.all(16),
          child: BoundString(
            dataContext: itemContext.dataContext,
            value: data.coachingLine,
            builder: (BuildContext context, String? coaching) {
              return Text(
                coaching ?? '',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              );
            },
          ),
        ),
        // D-03: the REAL native canvas, under the stable key, in a non-scrolling
        // region. No scoring callbacks (D-07). The instrumentation wrapper prints
        // its lifecycle so a torn-down State is visible during the A/B.
        Expanded(
          child: _InstrumentedCanvas(
            key: kEmbeddedCanvasKey,
            letterId: data.letterId,
          ),
        ),
      ],
    );
  },
);

/// Spike-local instrumentation wrapper — prints on initState/dispose so the A/B can
/// SEE whether a GenUI surface rebuild tore down the canvas State mid-trace (Pitfall 1).
///
/// The print lives HERE, never in durable stroke_canvas.dart. It hosts the REAL
/// StrokeCanvas with baa's read-only fixture strokes and no callbacks (D-07).
class _InstrumentedCanvas extends StatefulWidget {
  const _InstrumentedCanvas({super.key, required this.letterId});

  final String letterId;

  @override
  State<_InstrumentedCanvas> createState() => _InstrumentedCanvasState();
}

class _InstrumentedCanvasState extends State<_InstrumentedCanvas> {
  @override
  void initState() {
    super.initState();
    debugPrint(
      '[spike] embedded canvas State CREATED for "${widget.letterId}" '
      '(GlobalKey=$kEmbeddedCanvasKey) — fresh ink surface; should fire ONCE if '
      'the GlobalKey preserves State across GenUI rebuilds',
    );
  }

  @override
  void dispose() {
    debugPrint(
      '[spike] embedded canvas State DISPOSED for "${widget.letterId}" '
      '(GlobalKey=$kEmbeddedCanvasKey) — if this fires on a GenUI rebuild (not an '
      'arm switch), even a GlobalKey did not save the canvas (Pitfall 1 -> DROP)',
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The canvas is itself a plain StatefulWidget; its OWN State (_activePoints /
    // _completedStrokes) is what the stable key protects. We give it a NESTED stable
    // key too so its identity is anchored under our wrapper.
    return const StrokeCanvas(
      key: ValueKey<String>('spike-embedded-stroke-canvas'),
      referenceStrokes: baaReferenceStrokes,
    );
  }
}
