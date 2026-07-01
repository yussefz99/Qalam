// Regression: editing the nickname and tapping Save must not crash the dialog's
// close-animation frame ("TextEditingController used after being disposed" → the
// on-device `_dependents.isEmpty` assertion). Mirrors the Forgot-PIN repro.

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:qalam/data/app_database.dart';
import 'package:qalam/l10n/app_localizations.dart';
import 'package:qalam/screens/settings_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Edit learner → change nickname → Save does not crash', (
    tester,
  ) async {
    final executor = NativeDatabase.memory();
    final db = AppDatabase(executor);
    addTearDown(() => executor.close());

    // Seed a profile so the edit dialog opens.
    await db.createProfile(
      nicknameId: 'nick_star',
      avatarId: 'avatar_1',
      grade: 'kg',
      startingLessonId: 'lesson_01',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWith((ref) => db)],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const SettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Open the edit dialog.
    await tester.tap(find.byKey(const Key('settingsEditLearner')));
    await tester.pumpAndSettle();

    // Change the nickname and save.
    await tester.enterText(
      find.byKey(const Key('editLearnerNickname')),
      'Sunny',
    );
    await tester.tap(find.byKey(const Key('saveLearnerProfile')));
    await tester.pumpAndSettle();

    // No exception during the dialog's exit animation.
    expect(tester.takeException(), isNull);
    // And the change persisted.
    final profile = await db.getProfile();
    expect(profile?.nicknameId, 'Sunny');
  });
}
