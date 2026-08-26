import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_router.dart';
import 'core/config.dart';
import 'core/locale_controller.dart';
import 'features/driver/gps_service.dart';
import 'l10n/app_localizations.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConfig.loadCached();
  runApp(const ProviderScope(child: DireExpressApp()));
}

class DireExpressApp extends ConsumerWidget {
  const DireExpressApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final locale = ref.watch(localeControllerProvider);
    ref.watch(driverLocationControllerProvider.notifier);

    return MaterialApp.router(
      title: 'Dire Express',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      locale: locale,
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
