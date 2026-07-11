// Plan 18-06 — the across-session child-model repository (Req 2 / D-16).
//
// The compiled per-child profile (strengths / struggles / per-criterion EMA) is
// produced server-side by the nightly `compile_child` (18-09) and written to
// `child_models/{uid}` in Firestore (owner-read rule landed 18-05). This
// repository is the CLIENT side of D-16: it MIRRORS that profile into the Drift
// `ChildProfileMirror` so the FIRST session after a cold boot already knows the
// returning child — WITHOUT a network round-trip (Req 6 / the practice path never
// blocks).
//
//   • [get] reads the Drift mirror synchronously (a fast local read) and returns
//     the last-known [ChildModelSnapshot] — offline-safe, never a Firestore call.
//   • [refresh] does ONE-SHOT `child_models/{uid}.get()`, and on a non-empty doc
//     write-throughs the mirror. A permission-denied / offline / malformed read
//     keeps the last-known mirror — it NEVER throws and NEVER blocks. It is fired
//     FIRE-AND-FORGET from the boot provider (`child_model_providers.dart`), so it
//     is never on the selection/practice path (D-16 / T-18-06-02).
//
// SECURITY (T-18-06-01/04): the mirror + the profile doc carry ONLY derived,
// fixed-vocabulary, non-PII ids/EMAs (`<letter>/<criterion>` competency ids →
// counts/estimates). The repo only ever queries `child_models/{uid}` for the
// child's OWN uid (the owner-scoped rule from 18-05); no stroke point, no nickname,
// no geometry is ever read or stored. Values are never logged.

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:qalam/curriculum/child_model_snapshot.dart';
import 'app_database.dart';

/// Firestore-first, Drift-mirror-fallback reader of the compiled child model
/// (D-16). Boot reads the mirror; the Firestore refresh is fire-and-forget.
class ChildModelRepository {
  /// Production constructor — the Firestore instance is resolved LAZILY (only
  /// when [refresh] actually reads), so the offline [get] path never constructs
  /// `FirebaseFirestore.instance` (mirrors `CurriculumRepository`).
  ChildModelRepository(this._db, {FirebaseFirestore? firestore})
      : _firestoreOverride = firestore;

  /// Test/seam constructor: inject a Firestore instance (e.g. a
  /// `FakeFirebaseFirestore`) and run the live refresh path against it.
  ChildModelRepository.withFirestore(this._db, FirebaseFirestore firestore)
      : _firestoreOverride = firestore;

  final AppDatabase _db;

  FirebaseFirestore? _firestoreOverride;
  FirebaseFirestore get _firestore =>
      _firestoreOverride ??= FirebaseFirestore.instance;

  /// The top-level Firestore collection the nightly compiler writes to. The
  /// owner-read rule (18-05) permits a client to read ONLY `child_models/{uid}`
  /// where `request.auth.uid == uid`.
  static const String _collection = 'child_models';

  /// The last-known compiled profile, read SYNCHRONOUSLY from the Drift mirror —
  /// offline-safe, never a Firestore round-trip (Req 6 / D-16). Returns the
  /// neutral empty snapshot when no profile has been mirrored yet (cold boot).
  Future<ChildModelSnapshot> get(String uid) async {
    final row = await _db.getProfileMirror(uid);
    if (row == null) return ChildModelSnapshot.empty();
    return ChildModelSnapshot(
      strengths: _decodeStringList(row.strengths),
      struggles: _decodeStringList(row.struggles),
      perCriterion: _decodeDoubleMap(row.perCriterion),
    );
  }

  /// ONE-SHOT `child_models/{uid}.get()` → write-through the Drift mirror on a
  /// non-empty doc. NEVER throws and NEVER blocks the practice path: any
  /// permission-denied / offline / malformed read is swallowed and the last-known
  /// mirror is kept (T-18-06-02). Fired fire-and-forget from the boot provider.
  ///
  /// CRITICAL (D-16): this is the ONLY `.get()` in the child-model path; it is
  /// never awaited on the selection/practice path — the boot provider reads the
  /// mirror via [get] and kicks this off with `unawaited(...)`.
  Future<void> refresh(String uid) async {
    try {
      final doc = await _firestore.collection(_collection).doc(uid).get();
      final data = doc.data();
      if (!doc.exists || data == null || data.isEmpty) {
        // No compiled profile yet (or offline empty) — keep the last-known mirror.
        return;
      }
      await _db.setProfileMirror(
        uid: uid,
        strengths: _stringListFromDynamic(data['strengths']),
        struggles: _stringListFromDynamic(data['struggles']),
        perCriterion: _doubleMapFromDynamic(data['perCriterion']),
      );
    } catch (_) {
      // permission-denied / offline / decode failure → keep the last-known
      // mirror. The child never waits on Firestore; a failed refresh is a
      // display-only no-op (D-16 / T-18-06-02).
    }
  }

  // --- decode helpers (mirror JSON columns / Firestore dynamics → pure types) --

  /// Decode a JSON-encoded `List<String>` mirror column, `const []` on any
  /// malformed/empty value (never throws).
  static List<String> _decodeStringList(String encoded) {
    if (encoded.isEmpty) return const [];
    try {
      final decoded = jsonDecode(encoded);
      return _stringListFromDynamic(decoded);
    } catch (_) {
      return const [];
    }
  }

  /// Decode a JSON-encoded `Map<String, double>` mirror column, `const {}` on any
  /// malformed/empty value (never throws).
  static Map<String, double> _decodeDoubleMap(String encoded) {
    if (encoded.isEmpty) return const {};
    try {
      final decoded = jsonDecode(encoded);
      return _doubleMapFromDynamic(decoded);
    } catch (_) {
      return const {};
    }
  }

  /// Coerce a dynamic (Firestore list / decoded JSON) into a `List<String>`.
  static List<String> _stringListFromDynamic(Object? value) {
    if (value is! List) return const [];
    return [for (final e in value) e.toString()];
  }

  /// Coerce a dynamic (Firestore map / decoded JSON) into a `Map<String, double>`,
  /// keeping only `num` values (an EMA in [0, 1]).
  static Map<String, double> _doubleMapFromDynamic(Object? value) {
    if (value is! Map) return const {};
    final out = <String, double>{};
    value.forEach((k, v) {
      if (v is num) out[k.toString()] = v.toDouble();
    });
    return out;
  }
}
