import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/constants/app_constants.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/theme_provider.dart';
import 'l10n/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Disable runtime font fetching — fonts are bundled, no CDN stall needed
  GoogleFonts.config.allowRuntimeFetching = false;

  // Hive doesn't work well on web — skip it there
  if (!kIsWeb) {
    await Future.wait([
      Hive.initFlutter(),
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]),
    ]);
  }

  // Guard against empty keys (happens if --dart-define-from-file is not passed)
  const url = AppConstants.supabaseUrl;
  const key = AppConstants.supabaseAnonKey;
  if (url.isEmpty || key.isEmpty) {
    debugPrint(
        '⚠️  Supabase keys are empty! Run with: flutter run --dart-define-from-file=.env.local');
  }

  // Initialize Supabase
  await Supabase.initialize(
    url: url,
    anonKey: key,
  );

  runApp(
    const ProviderScope(
      child: HamroPasalApp(),
    ),
  );
}

class HamroPasalApp extends ConsumerWidget {
  const HamroPasalApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Hamro Pasal',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
