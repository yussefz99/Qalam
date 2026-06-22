// RED — implemented in 09-02 (PinService) / 09-03.
//
// Plan 09-01 (Wave 0) — the PIN security contract for the Parent Area (S1-11).
//
// INTENTIONALLY RED at Wave 0: imports the not-yet-built PinService from
// package:qalam/features/parent/pin_service.dart. A later plan (09-02) builds
// PinService over the existing AppDatabase k/v store and turns this green.
// Do NOT add a lib/ stub here.
//
// Encodes the T-09-01 / T-09-02 threat mitigations as executable assertions:
//   * the stored value is a SALTED HASH, never the plaintext PIN (T-09-01);
//   * the same PIN hashed twice yields DIFFERENT stored hashes (random salt);
//   * the brute-force cooldown PERSISTS across a simulated restart (T-09-02) —
//     the single most important security assertion in the phase: a child who
//     force-quits the app must NOT reset the throttle (RESEARCH Pitfall 1).
//
// SECURITY: this suite asserts only on booleans + hash-inequality. It NEVER
// prints/logs the PIN, salt, or hash (T-09-07, no-log convention).

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:qalam/data/app_database.dart';
import 'package:qalam/features/parent/pin_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // AppSettings keys the contract pins by their exact research names.
  const kPinHash = 'parentPinHash';
  const kPinSalt = 'parentPinSalt';

  late AppDatabase db;
  late NativeDatabase executor;
  late PinService pinService;

  setUp(() {
    executor = NativeDatabase.memory();
    db = AppDatabase(executor);
    pinService = PinService();
    // The injected executor is owned by the test (AppDatabase.close is a no-op
    // for injected executors).
    addTearDown(() => executor.close());
  });

  group('PinService hash / verify (T-09-01, S1-11)', () {
    test('setPin then verify with the SAME 4-digit PIN returns true', () async {
      await pinService.setPin(db, '1234');
      expect(
        await pinService.verify(db, '1234'),
        isTrue,
        reason: 'the correct PIN must verify',
      );
    });

    test('verify with a WRONG PIN returns false', () async {
      await pinService.setPin(db, '1234');
      expect(
        await pinService.verify(db, '9999'),
        isFalse,
        reason: 'an incorrect PIN must not verify',
      );
    });

    test(
      'the stored value is NEVER the plaintext PIN (hashed, T-09-01)',
      () async {
        await pinService.setPin(db, '1234');
        final storedHash = await db.getSetting(kPinHash);
        expect(
          storedHash,
          isNotNull,
          reason: 'setPin must persist a hash at parentPinHash',
        );
        expect(
          storedHash,
          isNot('1234'),
          reason: 'the PIN must be stored hashed, never as plaintext',
        );
      },
    );

    test('two setPin calls with the SAME PIN produce DIFFERENT stored hashes '
        '(random per-install salt at parentPinSalt)', () async {
      await pinService.setPin(db, '1234');
      final firstHash = await db.getSetting(kPinHash);
      final firstSalt = await db.getSetting(kPinSalt);

      await pinService.setPin(db, '1234');
      final secondHash = await db.getSetting(kPinHash);
      final secondSalt = await db.getSetting(kPinSalt);

      expect(
        firstSalt,
        isNotNull,
        reason: 'a per-install salt must be stored at parentPinSalt',
      );
      expect(
        secondSalt,
        isNot(firstSalt),
        reason: 'the salt must be freshly random on each setPin',
      );
      expect(
        secondHash,
        isNot(firstHash),
        reason: 'a random salt must make the same PIN hash differently',
      );
    });

    test('isPinSet is false before setPin, true after', () async {
      expect(
        await pinService.isPinSet(db),
        isFalse,
        reason: 'no PIN exists on a fresh install',
      );
      await pinService.setPin(db, '1234');
      expect(
        await pinService.isPinSet(db),
        isTrue,
        reason: 'isPinSet must report true once a PIN is created',
      );
    });

    test('resetPin removes the account-specific PIN verifier', () async {
      await pinService.setPin(db, '1234');
      await pinService.resetPin(db);
      expect(await pinService.isPinSet(db), isFalse);
      expect(await pinService.verify(db, '1234'), isFalse);
    });
  });

  group('persisted brute-force cooldown (T-09-02, S1-11)', () {
    test('a fresh database has no cooldown', () async {
      expect(
        await pinService.remainingCooldown(db),
        anyOf(isNull, Duration.zero),
        reason: 'no failures yet → no cooldown',
      );
    });

    test('registerSuccess clears any pending cooldown', () async {
      for (var i = 0; i < 5; i++) {
        await pinService.registerFailure(db);
      }
      await pinService.registerSuccess(db);
      final remaining = await pinService.remainingCooldown(db);
      expect(
        remaining,
        anyOf(isNull, Duration.zero),
        reason: 'a correct PIN must clear the throttle',
      );
    });

    test('5 consecutive failures set a non-null cooldown that SURVIVES a '
        'simulated restart (T-09-02 — the force-quit-bypass defense)', () async {
      // A shared in-memory store lets a "second" AppDatabase re-open the same
      // data — the closest analog to an app restart in a test (D-09 shape).
      final shared = DatabaseConnection(NativeDatabase.memory());

      final db1 = AppDatabase(shared.executor);
      final service = PinService();

      // Five wrong attempts trip the lock and write parentPinLockUntil.
      for (var i = 0; i < 5; i++) {
        await service.registerFailure(db1);
      }
      final lockUntil = await db1.getSetting('parentPinLockUntil');
      expect(
        lockUntil,
        isNotNull,
        reason: '5 failures must persist a parentPinLockUntil',
      );
      final beforeRestart = await service.remainingCooldown(db1);
      expect(beforeRestart, isNotNull);
      expect(
        beforeRestart! > Duration.zero,
        isTrue,
        reason: 'the lock is active immediately after tripping',
      );
      await db1.close();

      // "Restart": a fresh AppDatabase over the SAME underlying store. A child
      // who force-quits the app must NOT reset the throttle (Pitfall 1).
      final db2 = AppDatabase(shared.executor);
      final afterRestart = await service.remainingCooldown(db2);
      expect(
        afterRestart,
        isNotNull,
        reason: 'the cooldown must persist across a restart, not reset',
      );
      expect(
        afterRestart! > Duration.zero,
        isTrue,
        reason:
            'force-quitting must NOT bypass the brute-force cooldown '
            '(the single most important security assertion in Phase 9)',
      );
      await db2.close();
    });
  });
}
