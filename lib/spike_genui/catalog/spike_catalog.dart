// THROWAWAY SPIKE — Phase 11 GenUI/native-canvas kill-shot (Plan 11-02, Task 1).
//
// PURPOSE: composes the GenUI Catalog the spike drives. It is the basic catalog
// (so GenUI has Text/Column/etc. to lay out a mixed tree) PLUS the one custom
// present_activity item (stroke_canvas_item.dart) that hosts the real native
// StrokeCanvas (D-11 — exactly one custom tool).
//
// Verified against the INSTALLED genui 0.9.2 source: BasicCatalogItems.asCatalog()
// returns a Catalog; Catalog.copyWith(newItems: [...]) merges custom items by name.
// The merged catalog's systemPromptFragments carry both the basic-catalog rules AND
// the present_activity prompt fragment, so the model learns the tool from one place.
//
// This file edits no durable file; the SC-4 git-diff guard proves the sacred paths
// stay untouched for the whole spike.

import 'package:genui/genui.dart';

import '../agent/present_activity_tool.dart';
import 'stroke_canvas_item.dart';

/// The catalog id for the spike's merged catalog.
const String kSpikeCatalogId = 'com.qalam.spike.genui';

/// Builds the spike catalog: the basic GenUI catalog + the custom present_activity
/// item, with the present_activity system-prompt fragment appended.
///
/// `copyWith(newItems:)` adds present_activity to the basic items by name; the
/// catalogId is overridden so the surface controller resolves THIS catalog.
Catalog buildSpikeCatalog() {
  final Catalog base = BasicCatalogItems.asCatalog(
    systemPromptFragments: const <String>[presentActivitySystemPromptFragment],
  );
  return base.copyWith(
    newItems: <CatalogItem>[presentActivityItem],
    catalogId: kSpikeCatalogId,
  );
}
