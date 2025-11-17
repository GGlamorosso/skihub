import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../services/supabase_service.dart';
import '../services/moderation_service.dart' show navigatorKey;
import '../features/auth/presentation/auth_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/signup_screen.dart';
import '../features/auth/presentation/forgot_password_screen.dart';
import '../features/onboarding/presentation/splash_screen.dart';
import '../features/onboarding/presentation/name_screen.dart';
import '../features/onboarding/presentation/age_screen.dart';
import '../features/onboarding/presentation/photo_screen.dart';
import '../features/onboarding/presentation/level_style_screen.dart';
import '../features/onboarding/presentation/objectives_screen.dart';
import '../features/onboarding/presentation/languages_screen.dart';
import '../features/onboarding/presentation/gps_tracker_screen.dart';
import '../features/onboarding/presentation/station_dates_screen.dart';
import '../features/onboarding/presentation/onboarding_complete_screen.dart';
import '../features/feed/presentation/swipe_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/profile/presentation/edit_profile_screen.dart';
import '../features/profile/presentation/photo_gallery_screen.dart';
import '../features/profile/presentation/moderation_history_screen.dart';
import '../features/chat/presentation/matches_screen.dart';
import '../features/chat/presentation/chat_screen.dart';
import '../features/tracking/presentation/tracker_screen.dart';
import '../features/tracking/presentation/stats_screen.dart';

/// Routes de l'application
class AppRoutes {
  static const String splash = '/';
  static const String auth = '/auth';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';
  
  // Onboarding
  static const String onboardingName = '/onboarding/name';
  static const String onboardingAge = '/onboarding/age';
  static const String onboardingPhoto = '/onboarding/photo';
  static const String onboardingLevel = '/onboarding/level';
  static const String onboardingObjectives = '/onboarding/objectives';
  static const String onboardingLanguages = '/onboarding/languages';
  static const String onboardingStationDates = '/onboarding/station-dates';
  static const String onboardingGps = '/onboarding/gps';
  static const String onboardingComplete = '/onboarding/complete';
  
  // Main app
  static const String feed = '/feed';
  static const String candidateDetails = '/candidate-details';
  static const String matches = '/matches';
  static const String chat = '/chat';
  static const String profile = '/profile';
  static const String editProfile = '/edit-profile';
  static const String photoGallery = '/photo-gallery';
  static const String moderationHistory = '/moderation-history';
  static const String tracker = '/tracker';
  static const String stats = '/stats';
  static const String settings = '/settings';
  static const String premium = '/premium';
}

/// Configuration du router principal
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    
    // Redirect logic basé sur l'état d'authentification
    redirect: (context, state) async {
      final isAuthenticated = SupabaseService.instance.isAuthenticated;
      final location = state.matchedLocation;
      
      // Si pas d'auth et pas sur écrans auth/splash -> redirect auth
      if (!isAuthenticated && 
          !location.startsWith('/auth') && 
          !location.startsWith('/login') &&
          !location.startsWith('/signup') &&
          location != '/') {
        return AppRoutes.auth;
      }
      
      // Si authentifié, vérifier onboarding
      if (isAuthenticated) {
        // Si sur écrans auth -> vérifier onboarding
        if (location.startsWith('/auth') || 
            location.startsWith('/login') || 
            location.startsWith('/signup')) {
          
          try {
            final userId = SupabaseService.instance.currentUserId!;
            final response = await SupabaseService.instance.from('users')
                .select('onboarding_completed')
                .eq('id', userId)
                .maybeSingle(); // Use maybeSingle() to handle 0 rows
            
            // If no profile exists, go to onboarding
            if (response == null) {
              return AppRoutes.onboardingName;
            }
            
            final isOnboardingComplete = response['onboarding_completed'] == true;
            
            if (!isOnboardingComplete && !location.startsWith('/onboarding')) {
              return AppRoutes.onboardingName;
            } else if (isOnboardingComplete) {
              return AppRoutes.feed;
            }
          } catch (e) {
            // Erreur de vérification -> aller vers onboarding par sécurité
            return AppRoutes.onboardingName;
          }
        }
        
        // Si sur onboarding mais déjà complet -> feed
        if (location.startsWith('/onboarding')) {
          try {
            final userId = SupabaseService.instance.currentUserId!;
            final response = await SupabaseService.instance.from('users')
                .select('onboarding_completed')
                .eq('id', userId)
                .maybeSingle(); // Use maybeSingle() to handle 0 rows
            
            if (response != null && response['onboarding_completed'] == true) {
              return AppRoutes.feed;
            }
          } catch (e) {
            // Continue vers onboarding en cas d'erreur
          }
        }
      }
      
      return null; // Pas de redirection
    },
    
    routes: [
      // Splash
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      
      // Auth
      GoRoute(
        path: AppRoutes.auth,
        name: 'auth',
        builder: (context, state) => const AuthScreen(),
      ),
      
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      
      GoRoute(
        path: AppRoutes.signup,
        name: 'signup',
        builder: (context, state) => const SignupScreen(),
      ),
      
      GoRoute(
        path: AppRoutes.forgotPassword,
        name: 'forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      
      // Onboarding
      GoRoute(
        path: AppRoutes.onboardingName,
        name: 'onboarding-name',
        builder: (context, state) => const NameScreen(),
      ),
      
      GoRoute(
        path: AppRoutes.onboardingAge,
        name: 'onboarding-age',
        builder: (context, state) => const AgeScreen(),
      ),
      
      GoRoute(
        path: AppRoutes.onboardingPhoto,
        name: 'onboarding-photo',
        builder: (context, state) => const PhotoScreen(),
      ),
      
      GoRoute(
        path: AppRoutes.onboardingLevel,
        name: 'onboarding-level',
        builder: (context, state) => const LevelStyleScreen(),
      ),
      
      GoRoute(
        path: AppRoutes.onboardingObjectives,
        name: 'onboarding-objectives',
        builder: (context, state) => const ObjectivesScreen(),
      ),
      
      GoRoute(
        path: AppRoutes.onboardingLanguages,
        name: 'onboarding-languages',
        builder: (context, state) => const LanguagesScreen(),
      ),
      
      GoRoute(
        path: AppRoutes.onboardingStationDates,
        name: 'onboarding-station-dates',
        builder: (context, state) => const StationDatesScreen(),
      ),
      
      GoRoute(
        path: AppRoutes.onboardingGps,
        name: 'onboarding-gps',
        builder: (context, state) => const GpsTrackerScreen(),
      ),
      
      GoRoute(
        path: AppRoutes.onboardingComplete,
        name: 'onboarding-complete',
        builder: (context, state) => const OnboardingCompleteScreen(),
      ),
      
      // Main app
      GoRoute(
        path: AppRoutes.feed,
        name: 'feed',
        builder: (context, state) => const SwipeScreen(),
      ),
      
      GoRoute(
        path: '${AppRoutes.candidateDetails}/:candidateId',
        name: 'candidate-details',
        builder: (context, state) {
          final candidateId = state.pathParameters['candidateId']!;
          // TODO S3: Récupérer candidate depuis state ou API
          // Pour l'instant, placeholder
          return Scaffold(
            body: Center(
              child: Text('Détails candidat: $candidateId'),
            ),
          );
        },
      ),
      
      GoRoute(
        path: AppRoutes.profile,
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      
      GoRoute(
        path: AppRoutes.editProfile,
        name: 'edit-profile',
        builder: (context, state) => const EditProfileScreen(),
      ),
      
      GoRoute(
        path: AppRoutes.matches,
        name: 'matches',
        builder: (context, state) => const MatchesScreen(),
      ),
      
      GoRoute(
        path: '${AppRoutes.chat}/:matchId',
        name: 'chat',
        builder: (context, state) {
          final matchId = state.pathParameters['matchId']!;
          return ChatScreen(matchId: matchId);
        },
      ),
      
      GoRoute(
        path: AppRoutes.photoGallery,
        name: 'photo-gallery',
        builder: (context, state) => const PhotoGalleryScreen(),
      ),
      
      GoRoute(
        path: AppRoutes.moderationHistory,
        name: 'moderation-history',
        builder: (context, state) => const ModerationHistoryScreen(),
      ),
      
      GoRoute(
        path: AppRoutes.tracker,
        name: 'tracker',
        builder: (context, state) => const TrackerScreen(),
      ),
      
      GoRoute(
        path: AppRoutes.stats,
        name: 'stats',
        builder: (context, state) => const StatsScreen(),
      ),
    ],
    
    // Error screen
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Erreur de navigation: ${state.error}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.splash),
              child: const Text('Retour à l\'accueil'),
            ),
          ],
        ),
      ),
    ),
  );
});

/// Extensions utiles pour navigation
extension AppRouterExtension on BuildContext {
  void goToAuth() => go(AppRoutes.auth);
  void goToLogin() => go(AppRoutes.login);
  void goToSignup() => go(AppRoutes.signup);
  void goToOnboardingName() => go(AppRoutes.onboardingName);
  void goToFeed() => go(AppRoutes.feed);
  
  void goBack() => pop();
  bool canGoBack() => canPop();
}
