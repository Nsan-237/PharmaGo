import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/l10n/app_localizations.dart';
import 'core/router/app_router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: PharmaGoApp(),
    ),
  );
}

class PharmaGoApp extends ConsumerWidget {
  const PharmaGoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLang = ref.watch(localeProvider);

    return MaterialApp.router(
      title: 'PharmaGo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: appRouter,
      locale: Locale(currentLang == AppLanguage.fr ? 'fr' : 'en'),
    );
  }
}
