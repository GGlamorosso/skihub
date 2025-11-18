import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config/app_config.dart';
import 'core/config/supabase_config.dart';
import 'core/services/analytics_service.dart';
import 'core/services/crash_reporting_service.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'features/notifications/services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize app config for production
  AppConfig.initialize(Environment.production);
  
  // Initialize Supabase
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
  );
  
  // Initialize crash reporting with production settings
  await CrashReportingService.initialize(
    enableInDevMode: false,
    enableUserInteractionLogging: false,
  );
  
  // Initialize analytics with production settings
  await AnalyticsService().initialize();
  
  // Initialize notifications
  await NotificationService().initialize();
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  runApp(
    const ProviderScope(
      child: CrewSnowApp(),
    ),
  );
}

class CrewSnowApp extends ConsumerWidget {
  const CrewSnowApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    
    return MaterialApp.router(
      title: 'CrewSnow',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
      debugShowCheckedModeBanner: false, // No debug banner in prod
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(MediaQuery.of(context).textScaleFactor.clamp(0.8, 1.4)),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
