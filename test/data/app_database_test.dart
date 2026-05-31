// Wave-0 validation scaffold — D-09 (Drift persistence survives a restart).
//
// INTENTIONALLY RED at Wave 0: imports package:qalam/data/app_database.dart,
// which does not yet exist. A later plan builds the Drift AppDatabase and turns
// this green. Do NOT add a lib/ stub here.
//
// Proof: write a key/value through the settings API, then simulate an app
// restart by closing the DB and opening a SECOND AppDatabase over the same
// in-memory file, and assert the value survived. NativeDatabase.memory() keeps
// the test hermetic (no on-disk file, no path_provider).

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:qalam/data/app_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a persisted value survives a simulated restart (D-09)', () async {
    // A shared in-memory database file lets a "second" AppDatabase instance
    // re-open the same data — the closest analog to an app restart in a test.
    final shared = DatabaseConnection(NativeDatabase.memory());

    final db1 = AppDatabase(shared.executor);
    await db1.setSetting('last_letter', 'baa');
    expect(await db1.getSetting('last_letter'), 'baa');
    await db1.close();

    // "Restart": a fresh AppDatabase over the same underlying store.
    final db2 = AppDatabase(shared.executor);
    expect(await db2.getSetting('last_letter'), 'baa');
    await db2.close();
  });
}
