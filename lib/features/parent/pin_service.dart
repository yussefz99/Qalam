// Pure-Dart parent-PIN security core — Phase 9 (S1-11, Plan 09-02).
//
// Stores a 4-digit parent PIN as a SALTED PBKDF2-HMAC-SHA256 verifier over the
// existing AppSettings k/v table — never plaintext, never reversible — and a
// PERSISTED brute-force cooldown that survives a force-quit (the realistic
// adversary is the child; RESEARCH Pitfall 1 / threats T-09-01 / T-09-02).
//
// SECURITY (binding, 09-PATTERNS no-log convention):
//   * The PIN, salt, and hash are NEVER printed / debugPrinted / logged — not
//     even in debug builds. The only values that ever leave this file are a
//     base64 hash, a base64 salt, an int fail-count, and an epoch-ms lockUntil.
//   * The verifier compare is CONSTANT-TIME (XOR-accumulate, no early-out) so a
//     timing side-channel cannot leak how many leading digits matched (T-09-06).
//   * Storage is one-way only: flutter_secure_storage is deliberately NOT used —
//     a one-way hash needs no recovery (T-09-08, research rejects it).
//
// This is widget-free pure Dart so it is unit-testable without a binding.

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/app_database.dart';

part 'pin_service.g.dart';

/// Salted PBKDF2-HMAC-SHA256 PIN hash/verify + a Drift-persisted brute-force
/// cooldown. All persistence lives in the existing AppSettings table — no new
/// Drift table and no schemaVersion bump (still 4).
class PinService {
  // ---------------------------------------------------------------------------
  // AppSettings key constants (exact research names — pinned by the RED tests).
  // ---------------------------------------------------------------------------
  static const String keyHash = 'parentPinHash';
  static const String keySalt = 'parentPinSalt';
  static const String keyFailCount = 'parentPinFailCount';
  static const String keyLockUntil = 'parentPinLockUntil';

  /// Proportionate for a local 4-digit PIN over a low-value asset whose
  /// realistic adversary is a curious child, not a forensic extraction. The
  /// persisted cooldown is the primary brute-force defense; ≥100k iters make a
  /// stolen-DB offline guess non-trivial (RESEARCH A1, ratified at review).
  static const int _iterations = 100000;

  /// Lock after this many consecutive wrong attempts (D-08).
  static const int _maxFailures = 5;

  /// Cooldown window once locked (D-08).
  static const Duration _cooldown = Duration(seconds: 30);

  /// 16-byte salt (RESEARCH Pattern 1).
  static const int _saltBytes = 16;

  /// Derive a single 32-byte PBKDF2 block (dkLen == hLen == 32) over the
  /// `crypto` package's HMAC-SHA256 — RFC 2898, sufficient for a stored
  /// verifier. crypto has no built-in KDF, so the iteration loop is hand-rolled
  /// (the only thing worth hand-writing here; the hash itself is never
  /// hand-rolled).
  Uint8List _pbkdf2(String pin, Uint8List salt) {
    final hmac = Hmac(sha256, utf8.encode(pin));
    // U_1 = HMAC(pin, salt || INT(1)); INT(1) is the big-endian block index.
    var u = hmac.convert(<int>[...salt, 0, 0, 0, 1]).bytes;
    final out = Uint8List.fromList(u);
    for (var i = 1; i < _iterations; i++) {
      u = hmac.convert(u).bytes;
      for (var j = 0; j < out.length; j++) {
        out[j] ^= u[j];
      }
    }
    return out;
  }

  /// Create (or replace) the parent PIN: generate a fresh per-install salt with
  /// [Random.secure], derive the verifier, and base64-store both. Calling this
  /// twice with the same PIN yields DIFFERENT stored hashes (fresh salt).
  Future<void> setPin(AppDatabase db, String pin) async {
    final rng = Random.secure();
    final salt = Uint8List.fromList(
      List<int>.generate(_saltBytes, (_) => rng.nextInt(256)),
    );
    final hash = _pbkdf2(pin, salt);
    await db.setSetting(keySalt, base64Encode(salt));
    await db.setSetting(keyHash, base64Encode(hash));
  }

  /// True iff [pin] matches the stored verifier. Re-derives with the stored
  /// salt and compares CONSTANT-TIME (no early-out on first mismatch).
  Future<bool> verify(AppDatabase db, String pin) async {
    final saltB64 = await db.getSetting(keySalt);
    final hashB64 = await db.getSetting(keyHash);
    if (saltB64 == null || hashB64 == null) return false;
    final got = _pbkdf2(pin, base64Decode(saltB64));
    final want = base64Decode(hashB64);
    if (got.length != want.length) return false;
    var diff = 0;
    for (var i = 0; i < got.length; i++) {
      diff |= got[i] ^ want[i];
    }
    return diff == 0;
  }

  /// True once a PIN has been created on this install.
  Future<bool> isPinSet(AppDatabase db) async =>
      (await db.getSetting(keyHash)) != null;

  // ---------------------------------------------------------------------------
  // Persisted brute-force cooldown (RESEARCH Pattern 2 / T-09-02).
  // Stores ONLY an int count + an epoch-ms lockUntil — never PIN material. The
  // counter lives in Drift, NOT in memory, so a force-quit cannot reset it.
  // ---------------------------------------------------------------------------

  /// The remaining cooldown, or null when not locked. Reads the persisted
  /// lockUntil vs. now, so it is correct across an app restart.
  Future<Duration?> remainingCooldown(AppDatabase db) async {
    final until = int.tryParse(await db.getSetting(keyLockUntil) ?? '');
    if (until == null) return null;
    final delta = until - DateTime.now().millisecondsSinceEpoch;
    return delta > 0 ? Duration(milliseconds: delta) : null;
  }

  /// Record one wrong attempt. On the [_maxFailures]-th consecutive failure,
  /// persist a lockUntil = now + [_cooldown] and reset the window counter.
  Future<void> registerFailure(AppDatabase db) async {
    final n = (int.tryParse(await db.getSetting(keyFailCount) ?? '0') ?? 0) + 1;
    await db.setSetting(keyFailCount, '$n');
    if (n >= _maxFailures) {
      final until = DateTime.now().add(_cooldown).millisecondsSinceEpoch;
      await db.setSetting(keyLockUntil, '$until');
      // Reset the window after locking so the next batch starts clean.
      await db.setSetting(keyFailCount, '0');
    }
  }

  /// A correct PIN clears the throttle (count + lock).
  Future<void> registerSuccess(AppDatabase db) async {
    await db.setSetting(keyFailCount, '0');
    await db.setSetting(keyLockUntil, '0');
  }

  Future<void> resetPin(AppDatabase db) async {
    await db.deleteSetting(keyHash);
    await db.deleteSetting(keySalt);
    await db.deleteSetting(keyFailCount);
    await db.deleteSetting(keyLockUntil);
  }
}

/// Riverpod-codegen provider for the pure-Dart PIN service. Codegen is allowed
/// here because no method signature returns a Drift data class — only bool /
/// void / Duration (09-PATTERNS: InvalidTypeException only fires on Drift-typed
/// return values).
@Riverpod(keepAlive: true)
PinService pinService(Ref ref) => PinService();
