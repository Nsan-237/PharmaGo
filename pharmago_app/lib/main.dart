import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/l10n/app_localizations.dart';
import 'core/router/app_router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    DevicePreview(
      // Only active on web/desktop builds — disabled on real devices
      enabled: kIsWeb,
      defaultDevice: Devices.ios.iPhone13,
      builder: (context) => const ProviderScope(
        child: PharmaGoApp(),
      ),
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
      routerConfig: ref.watch(appRouterProvider),
      locale: DevicePreview.locale(context) ??
          Locale(currentLang == AppLanguage.fr ? 'fr' : 'en'),
      builder: DevicePreview.appBuilder,
    );
  }
}
