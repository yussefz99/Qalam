// Plan 18-06 — the child-model provider wiring (Req 2 / Req 6 / D-16).
//
// The boot read of the across-session child model, plus the keepAlive repository
// providers. Two hard rules, both honored here:
//
//  1. HAND-WRITTEN providers, NOT @riverpod codegen. `childModelProvider` reads
//     from the Drift mirror; a Drift-data-class-returning @riverpod functional
//     provider throws `InvalidTypeException` (Pitfall 6 / the Phase-05
//     `childProfileProvider` precedent). It is a plain `FutureProvider`; the repo
//     providers are plain keepAlive `Provider`s. Never a bare
//     `StreamProvider.future` (the Riverpod-3 stream-pause hang).
//
//  2. The practice path NEVER blocks on Firestore (Req 6 / D-16). `childModelProvider`
//     reads the last-known mirror synchronously (a fast local Drift read) and
//     returns it; the Firestore refresh is fired FIRE-AND-FORGET (`unawaited`) so a
//     network round-trip is never awaited before the returning child is known.
//
// SECURITY: the mirror + the profile doc carry only derived, fixed-vocabulary,
// non-PII ids/EMAs (T-18-06-01); the repo reads only the child's OWN uid
// (T-18-06-04).

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:qalam/curriculum/child_model_snapshot.dart';
import 'package:qalam/data/app_database.dart';
import 'package:qalam/data/arc_state_repository.dart';
import 'package:qalam/data/child_model_repository.dart';
import 'package:qalam/data/evidence_repository.dart';

/// keepAlive `Provider` for [ChildModelRepository] — mirrors the
/// appDatabaseProvider / graphPositionRepository keepAlive pattern (D-11). Uses the
/// real (lazily-resolved) `FirebaseFirestore.instance`; hand-written so no @riverpod
/// codegen touches a Drift-adjacent read (Pitfall 6).
final childModelRepositoryProvider = Provider<ChildModelRepository>(
  (ref) => ChildModelRepository(ref.watch(appDatabaseProvider)),
);

/// keepAlive `Provider` for [ArcStateRepository] — the remediation-arc resume
/// bridge (D-12). Hand-written keepAlive `Provider`.
final arcStateRepositoryProvider = Provider<ArcStateRepository>(
  (ref) => ArcStateRepository(ref.watch(appDatabaseProvider)),
);

/// keepAlive `Provider` for [EvidenceRepository] — the offline evidence-digest
/// drain (D-14). Hand-written keepAlive `Provider`.
final evidenceRepositoryProvider = Provider<EvidenceRepository>(
  (ref) => EvidenceRepository(ref.watch(appDatabaseProvider)),
);

/// The boot read of the compiled across-session child model (Req 2 / D-16).
///
/// A HAND-WRITTEN `FutureProvider` (NOT @riverpod codegen — Pitfall 6): it reads
/// the last-known Drift mirror SYNCHRONOUSLY (offline-safe, never a Firestore
/// round-trip) and returns it, THEN fires the Firestore refresh FIRE-AND-FORGET so
/// the practice path is never blocked on the network (Req 6). The refresh
/// write-throughs the mirror for the NEXT boot; it is never awaited here.
///
/// Resolves to [ChildModelSnapshot.empty] on a cold boot (no compiled profile yet)
/// — the policy treats that as "no across-session signal", never a false struggle.
final childModelProvider = FutureProvider<ChildModelSnapshot>((ref) async {
  final uid = ref.watch(accountDatabaseIdProvider);
  final repo = ref.watch(childModelRepositoryProvider);

  // Boot: the last-known mirror, read synchronously (local Drift) — offline-safe.
  final snapshot = await repo.get(uid);

  // Fire-and-forget the Firestore refresh — NEVER awaited before returning, so the
  // selection/practice path never blocks on a round-trip (Req 6 / D-16). The
  // refresh never throws (it keeps the last-known mirror on any failure).
  unawaited(repo.refresh(uid));

  return snapshot;
});
