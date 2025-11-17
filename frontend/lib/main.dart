import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';

import 'firebase_options.dart';
import 'config/env_config.dart';
import 'services/supabase_service.dart';
import 'services/moderation_service.dart';
import 'services/local_storage_service.dart';
import 'services/firebase_service.dart';
import 'services/tracking_service.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

// Import navigator key

/// Logger global pour l'application
final Logger logger = Logger(
  printer: PrettyPrinter(
    methodCount: 2,
    errorMethodCount: 8,
    lineLength: 120,
    colors: true,
    printEmojis: true,
    printTime: true,
  ),
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Configuration système
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  
  // Configuration status bar
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );
  
  try {
    // Configurer Google Fonts (désactiver runtime fetching)
    GoogleFonts.config.allowRuntimeFetching = false;
    
    // Initialiser Firebase EN PREMIER (avant tout autre service)
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // Charger configuration environnement
    await EnvConfig.load();
    EnvConfig.validate();
    
    // Initialiser les services Firebase (Crashlytics, Messaging)
    await FirebaseService.instance.initialize();
    
    // Initialiser Supabase
    await SupabaseService.initialize();
    
    // Initialiser service de modération
    await ModerationService.instance.initialize();
    
    // Initialiser stockage local
    await LocalStorageService.instance.initialize();
    
    // Vérifier permissions GPS (en arrière-plan, ne bloque pas le démarrage)
    try {
      final trackingService = TrackingService.instance;
      final hasPermissions = await trackingService.checkPermissions();
      if (hasPermissions) {
        logger.i('📍 GPS permissions granted');
      } else {
        logger.w('⚠️ GPS permissions not granted - location features may be limited');
      }
    } catch (e) {
      logger.w('⚠️ GPS permission check failed: $e');
    }
    
    logger.i('🚀 CrewSnow application starting...');
    
    runApp(const ProviderScope(child: CrewSnowApp()));
  } catch (e, stackTrace) {
    logger.e('❌ Application initialization failed: $e\n$stackTrace');
    
    // Afficher écran d'erreur de base
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Erreur d\'initialisation',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  e.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    // Restart app (simple exit, OS will restart)
                    SystemNavigator.pop();
                  },
                  child: const Text('Redémarrer'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CrewSnowApp extends ConsumerWidget {
  const CrewSnowApp({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    
    return MaterialApp.router(
      title: EnvConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      
      // Navigation avec key pour notifications
      routerConfig: router,
      
      // Localisation (pour S1, juste FR)
      locale: const Locale('fr', 'FR'),
      supportedLocales: const [
        Locale('fr', 'FR'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      
      // Configuration globale
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.noScaling, // Pas de scaling système pour S1
          ),
          child: child!,
        );
      },
    );
  }
}

/// Écran de chargement global
class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key, this.message = 'Chargement...'});
  
  final String message;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFF4B8A), Color(0xFFFFFFFF)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo / animation
              Container(
                width: 120,
                height: 120,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x40FF4B8A),
                      blurRadius: 20,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    '❄️',
                    style: TextStyle(fontSize: 48),
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              const Text(
                'CrewSnow',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              
              const SizedBox(height: 8),
              
              Text(
                message,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
              
              const SizedBox(height: 32),
              
              const CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
