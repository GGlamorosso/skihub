import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../services/supabase_service.dart';
import '../../../models/user_profile.dart';

/// État d'authentification
@immutable
class AuthState {
  const AuthState({
    this.user,
    this.profile,
    this.isLoading = false,
    this.error,
  });
  
  final User? user;
  final UserProfile? profile;
  final bool isLoading;
  final String? error;
  
  bool get isAuthenticated => user != null;
  bool get hasError => error != null;
  bool get hasProfile => profile != null;
  
  AuthState copyWith({
    User? user,
    UserProfile? profile,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      user: user ?? this.user,
      profile: profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Controller d'authentification
class AuthController extends StateNotifier<AuthState> {
  AuthController() : super(const AuthState()) {
    _init();
  }
  
  final _supabase = SupabaseService.instance;
  
  void _init() {
    // Écouter les changements d'état d'auth
    _supabase.authStateStream.listen((data) {
      final event = data.event;
      final user = data.session?.user;
      
      if (event == AuthChangeEvent.signedIn && user != null) {
        state = state.copyWith(user: user, error: null);
        _loadUserProfile(user.id);
      } else if (event == AuthChangeEvent.signedOut) {
        state = const AuthState();
      }
    });
    
    // Charger utilisateur existant si session active
    final currentUser = _supabase.currentUser;
    if (currentUser != null) {
      state = state.copyWith(user: currentUser);
      _loadUserProfile(currentUser.id);
    }
  }
  
  /// Inscription
  Future<void> signUp({
    required String email,
    required String password,
    VoidCallback? onSuccess,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      final response = await _supabase.signUp(
        email: email,
        password: password,
        data: {
          'created_from': 'mobile_app',
        },
      );
      
      if (response.user != null) {
        // Créer profil de base
        await _createInitialProfile(response.user!);
        onSuccess?.call();
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
  
  /// Connexion
  Future<void> signIn({
    required String email,
    required String password,
    VoidCallback? onSuccess,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      await _supabase.signIn(
        email: email,
        password: password,
      );
      
      onSuccess?.call();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
  
  /// Déconnexion
  Future<void> signOut() async {
    try {
      await _supabase.signOut();
      state = const AuthState();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
  
  /// Charger profil utilisateur
  Future<void> _loadUserProfile(String userId) async {
    try {
      final response = await _supabase.from('users')
          .select()
          .eq('id', userId)
          .single();
      
      final profile = UserProfile.fromJson(response);
      state = state.copyWith(profile: profile, isLoading: false);
    } catch (e) {
      // Profil pas encore créé, normal pour nouveau user
      state = state.copyWith(isLoading: false);
    }
  }
  
  /// Créer profil initial après inscription
  Future<void> _createInitialProfile(User user) async {
    try {
      // Vérifier d'abord si le profil existe déjà
      final existing = await _supabase.from('users')
          .select('id')
          .eq('id', user.id)
          .maybeSingle();
      
      if (existing != null) {
        debugPrint('✅ Profile already exists for user ${user.id}');
        return;
      }
      
      // Créer le profil initial
      await _supabase.from('users').insert({
        'id': user.id,
        'email': user.email!,
        'username': _generateUsername(user.email!),
        'created_at': DateTime.now().toIso8601String(),
        'is_active': true,
        'last_active_at': DateTime.now().toIso8601String(),
        'onboarding_completed': false,
        // Autres champs remplis lors de l'onboarding
      });
      
      debugPrint('✅ Initial profile created for user ${user.id}');
    } catch (e, stackTrace) {
      // Log l'erreur complète pour debug
      debugPrint('❌ Profile creation error: $e');
      debugPrint('Stack trace: $stackTrace');
      
      // Si erreur de permission RLS, on peut essayer avec une Edge Function
      // Pour l'instant, on continue quand même - l'onboarding créera le profil
    }
  }
  
  /// Générer username à partir de l'email
  String _generateUsername(String email) {
    return email.split('@')[0].toLowerCase();
  }
  
  /// Refresh le profil
  Future<void> refreshProfile() async {
    final userId = state.user?.id;
    if (userId != null) {
      await _loadUserProfile(userId);
    }
  }
  
  /// Clear les erreurs
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Provider pour le controller d'auth
final authControllerProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController();
});

/// Provider pour accès rapide aux infos d'auth
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authControllerProvider).user;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authControllerProvider).isAuthenticated;
});

final userProfileProvider = Provider<UserProfile?>((ref) {
  return ref.watch(authControllerProvider).profile;
});
