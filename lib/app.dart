// QalamApp — the MaterialApp.router root.
//
// App chrome defaults to LTR (English); there is NO global Directionality.rtl —
// RTL is a per-content decision owned by ArabicText (D-05). supportedLocales is
// English-only and must NEVER include an Arabic locale (Pitfall 4); RTL is not
// coupled to locale.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'l10n/app_localizations.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

class QalamApp extends ConsumerWidget {
  const QalamApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      onGenerateTitle: (context) => 'Qalam',
      routerConfig: router,
      theme: qalamTheme, // app default is LTR
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: const <Locale>[Locale('en')], // English ONLY — never 'ar'
      debugShowCheckedModeBanner: false,
    );
  }
}
