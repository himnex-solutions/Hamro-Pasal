import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hamro_pasal/core/theme/app_theme.dart';
import 'package:hamro_pasal/core/theme/theme_provider.dart';
import 'package:hamro_pasal/core/router/app_router.dart';
import 'package:hamro_pasal/core/constants/supabase_constants.dart';
import 'package:hamro_pasal/core/services/local_db_service.dart';
import 'package:hamro_pasal/core/services/notification_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Use clean path-based URLs (e.g. /home/dashboard) instead of hash URLs (/#/home/dashboard)
  usePathUrlStrategy();

  // Disable runtime font fetching — bundle fonts locally instead
  // to avoid SocketException on devices without Google Fonts access.
  GoogleFonts.config.allowRuntimeFetching = false;

  await Supabase.initialize(
    url: SupabaseConstants.supabaseUrl,
    anonKey: SupabaseConstants.supabaseAnonKey,
  );

  await LocalDbService.initialize();
  await NotificationService.initialize();

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
    );
  }
}
