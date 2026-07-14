import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_localizations.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

class PagameApp extends ConsumerWidget {
  const PagameApp({super.key});
  @override Widget build(BuildContext context, WidgetRef ref) => MaterialApp.router(
    title: 'Págame',
    theme: AppTheme.light(),
    darkTheme: AppTheme.dark(),
    routerConfig: appRouter,
    localizationsDelegates: const [AppLocalizations.delegate, GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
    supportedLocales: const [Locale('es', 'DO'), Locale('en', 'US')],
  );
}
