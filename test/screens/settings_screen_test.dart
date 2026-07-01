import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:qalam/l10n/app_localizations.dart';
import 'package:qalam/providers/auth_providers.dart';
import 'package:qalam/screens/settings_screen.dart';
import 'package:qalam/services/auth_service.dart';

void main() {
  testWidgets('Home button returns to the home route', (tester) async {
    final router = GoRouter(
      initialLocation: '/settings',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => const Scaffold(body: Text('Home screen')),
        ),
        GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authServiceProvider.overrideWithValue(
            AuthService(
              MockFirebaseAuth(
                signedIn: true,
                mockUser: MockUser(
                  isAnonymous: false,
                  email: 'parent@example.com',
                ),
              ),
            ),
          ),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('settingsHomeButton')));
    await tester.pumpAndSettle();

    expect(find.text('Home screen'), findsOneWidget);
  });
}
