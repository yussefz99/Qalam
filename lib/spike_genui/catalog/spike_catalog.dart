// THROWAWAY SPIKE — Phase 11 GenUI/native-canvas kill-shot (Plan 11-02, Task 1).
//
// PURPOSE: composes the GenUI Catalog the spike drives. It is the basic catalog
// (so GenUI has Text/Column/etc. to lay out a mixed tree) PLUS the one custom
// present_activity item (stroke_canvas_item.dart) that hosts the real native
// StrokeCanvas (D-11 — exactly one custom tool).
//
// Verified against the INSTALLED genui 0.9.2 source: BasicCatalogItems.asCatalog()
// returns a Catalog whose catalogId is the canonical `basicCatalogId`
// ("https://a2ui.org/specification/v0_9/basic_catalog.json") AND whose
// systemPromptFragments include `basicCatalogRules`, which hardcodes that same id as
// the catalogId the model must emit. Catalog.copyWith(newItems: [...]) merges custom
// items by name WITHOUT changing the id.
//
// RUNTIME FINDING (on-device, Pixel Tablet emulator, 2026-06-21): an earlier version
// overrode the id via copyWith(catalogId: 'com.qalam.spike.genui'). That desynced the
// *registered* catalog id from the id the system-prompt rules tell the model to emit
// (the canonical URL), so the A2uiMessageProcessor threw `Catalog with id
// "...basic_catalog.json" not found`. Fix: do NOT override the id — keep the canonical
// basicCatalogId so the model's emitted catalogId resolves. present_activity is just
// added as one more item.
//
// This file edits no durable file; the SC-4 git-diff guard proves the sacred paths
// stay untouched for the whole spike.

import 'package:genui/genui.dart';

import '../agent/present_activity_tool.dart';
import 'stroke_canvas_item.dart';

/// Builds the spike catalog: the basic GenUI catalog + the custom present_activity
/// item, with the present_activity system-prompt fragment appended.
///
/// `copyWith(newItems:)` adds present_activity to the basic items by name and KEEPS
/// the base catalog's canonical `basicCatalogId`, so the surface controller resolves
/// the catalog under the exact id the model emits (per basicCatalogRules).
Catalog buildSpikeCatalog() {
  final Catalog base = BasicCatalogItems.asCatalog(
    systemPromptFragments: const <String>[presentActivitySystemPromptFragment],
  );
  return base.copyWith(
    newItems: <CatalogItem>[presentActivityItem],
  );
}
