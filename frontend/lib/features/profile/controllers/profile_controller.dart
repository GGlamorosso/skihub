import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';

import '../../../models/user_profile.dart';
import '../../../models/station.dart';
import '../../../services/user_service.dart';
import '../../../services/storage_service.dart';
import '../../../services/supabase_service.dart';

/// État du profil utilisateur
@immutable
class ProfileState {
  const ProfileState({
    this.profile,
    this.currentStation,
    this.photoUrls = const {},
    this.isLoading = false,
    this.isUpdating = false,
    this.error,
  });
  
  final UserProfile? profile;
  final UserStationStatus? currentStation;
  final Map<String, String> photoUrls; // storage_path -> signed_url
  final bool isLoading;
  final bool isUpdating;
  final String? error;
  
  bool get hasProfile => profile != null;
  bool get hasError => error != null;
  bool get isOnboardingComplete => profile?.verificationStatus != VerificationStatus.notSubmitted;
  
  ProfileState copyWith({
    UserProfile? profile,
    UserStationStatus? currentStation,
    Map<String, String>? photoUrls,
    bool? isLoading,
    bool? isUpdating,
    String? error,
  }) {
    return ProfileState(
      profile: profile ?? this.profile,
      currentStation: currentStation ?? this.currentStation,
      photoUrls: photoUrls ?? this.photoUrls,
      isLoading: isLoading ?? this.isLoading,
      isUpdating: isUpdating ?? this.isUpdating,
      error: error,
    );
  }
}

/// Controller pour gestion du profil
class ProfileController extends StateNotifier<ProfileState> {
  ProfileController() : super(const ProfileState());
  
  final _userService = UserService.instance;
  final _storageService = StorageService.instance;
  final _supabase = SupabaseService.instance;
  
  /// Charger profil utilisateur
  Future<void> loadProfile() async {
    final userId = _supabase.currentUserId;
    if (userId == null) {
      state = state.copyWith(error: 'Utilisateur non authentifié');
      return;
    }
    
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      final profile = await _userService.getUserProfile(userId);
      if (profile == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Profil non trouvé',
        );
        return;
      }
      
      // Charger station actuelle
      UserStationStatus? currentStation;
      try {
        // ✅ Corrigé : Utiliser limit(1) pour éviter l'erreur "multiple rows"
        // Si plusieurs stations actives, prendre la plus récente
        final stationResponse = await _supabase.from('user_station_status')
            .select('''
              *,
              stations(*)
            ''')
            .eq('user_id', userId)
            .eq('is_active', true)
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();
        
        if (stationResponse != null) {
          // ✅ Corrigé : Convertir snake_case vers camelCase pour le modèle
          final cleanedResponse = Map<String, dynamic>.from(stationResponse);
          
          // Convertir les clés snake_case vers camelCase
          cleanedResponse['stationId'] = cleanedResponse['station_id'];
          cleanedResponse['userId'] = cleanedResponse['user_id'];
          cleanedResponse['dateFrom'] = cleanedResponse['date_from'];
          cleanedResponse['dateTo'] = cleanedResponse['date_to'];
          cleanedResponse['radiusKm'] = cleanedResponse['radius_km'];
          cleanedResponse['isActive'] = cleanedResponse['is_active'];
          cleanedResponse['createdAt'] = cleanedResponse['created_at'];
          
          // Convertir stations(*) si présent
          if (cleanedResponse['stations'] != null) {
            final stationData = cleanedResponse['stations'] as Map<String, dynamic>;
            cleanedResponse['station'] = {
              'id': stationData['id'],
              'name': stationData['name'],
              'countryCode': stationData['country_code'],
              'region': stationData['region'],
              'latitude': stationData['latitude'],
              'longitude': stationData['longitude'],
              'elevationM': stationData['elevation_m'],
              'officialWebsite': stationData['official_website'],
              'seasonStartMonth': stationData['season_start_month'],
              'seasonEndMonth': stationData['season_end_month'],
              'isActive': stationData['is_active'] ?? true,
              'createdAt': stationData['created_at'],
            };
          }
          
          // Supprimer les clés snake_case pour éviter confusion
          cleanedResponse.remove('station_id');
          cleanedResponse.remove('user_id');
          cleanedResponse.remove('date_from');
          cleanedResponse.remove('date_to');
          cleanedResponse.remove('radius_km');
          cleanedResponse.remove('is_active');
          cleanedResponse.remove('created_at');
          cleanedResponse.remove('stations');
          
          currentStation = UserStationStatus.fromJson(cleanedResponse);
        }
      } catch (e) {
        debugPrint('No active station found: $e');
      }
      
      // Charger URLs des photos
      final photoUrls = await _loadPhotoUrls(profile.id);
      
      state = state.copyWith(
        profile: profile,
        currentStation: currentStation,
        photoUrls: photoUrls,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur de chargement: $e',
      );
    }
  }
  
  /// Mettre à jour profil
  Future<bool> updateProfile({
    String? username,
    String? bio,
    DateTime? birthDate,
    UserLevel? level,
    List<RideStyle>? rideStyles,
    List<String>? languages,
    List<String>? objectives,
  }) async {
    final userId = _supabase.currentUserId;
    if (userId == null) return false;
    
    try {
      state = state.copyWith(isUpdating: true, error: null);
      
      final success = await _userService.updateUserProfile(
        userId: userId,
        username: username,
        bio: bio,
        birthDate: birthDate,
        level: level,
        rideStyles: rideStyles,
        languages: languages,
        objectives: objectives,
      );
      
      if (success) {
        // Recharger le profil
        await loadProfile();
      }
      
      state = state.copyWith(isUpdating: false);
      return success;
    } catch (e) {
      state = state.copyWith(
        isUpdating: false,
        error: 'Erreur de mise à jour: $e',
      );
      return false;
    }
  }
  
  /// Uploader nouvelle photo
  Future<bool> uploadPhoto(File imageFile, {bool isMain = false}) async {
    final userId = _supabase.currentUserId;
    if (userId == null) return false;
    
    try {
      state = state.copyWith(isUpdating: true, error: null);
      
      final storagePath = await _storageService.uploadWithRetry(
        userId: userId,
        imageFile: imageFile,
        isMain: isMain,
      );
      
      if (storagePath != null) {
        // Recharger profil pour récupérer nouvelle photo
        await loadProfile();
        state = state.copyWith(isUpdating: false);
        return true;
      }
      
      state = state.copyWith(
        isUpdating: false,
        error: 'Échec upload photo',
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isUpdating: false,
        error: 'Erreur upload: $e',
      );
      return false;
    }
  }
  
  /// Mettre à jour station et dates
  Future<bool> updateStationStatus({
    required String stationId,
    required DateTime dateFrom,
    required DateTime dateTo,
    required int radiusKm,
  }) async {
    final userId = _supabase.currentUserId;
    if (userId == null) return false;
    
    try {
      state = state.copyWith(isUpdating: true, error: null);
      
      final success = await _userService.updateStationStatus(
        userId: userId,
        stationId: stationId,
        dateFrom: dateFrom,
        dateTo: dateTo,
        radiusKm: radiusKm,
      );
      
      if (success) {
        await loadProfile();
      }
      
      state = state.copyWith(isUpdating: false);
      return success;
    } catch (e) {
      state = state.copyWith(
        isUpdating: false,
        error: 'Erreur station: $e',
      );
      return false;
    }
  }
  
  /// Charger URLs signées pour les photos
  Future<Map<String, String>> _loadPhotoUrls(String userId) async {
    try {
      final photosResponse = await _supabase.from('profile_photos')
          .select('storage_path, moderation_status')
          .eq('user_id', userId)
          .eq('moderation_status', 'approved'); // Seulement photos approuvées
      
      final Map<String, String> urls = {};
      
      for (final photo in photosResponse) {
        final storagePath = photo['storage_path'] as String;
        final url = await _storageService.getSignedPhotoUrl(
          storagePath: storagePath,
          expiresInSeconds: 3600,
        );
        
        if (url != null) {
          urls[storagePath] = url;
        }
      }
      
      return urls;
    } catch (e) {
      debugPrint('Error loading photo URLs: $e');
      return {};
    }
  }
  
  /// Refresh profil
  Future<void> refresh() async {
    await loadProfile();
  }
  
  /// Clear erreurs
  void clearError() {
    state = state.copyWith(error: null);
  }
  
  /// Reset state
  void reset() {
    state = const ProfileState();
  }
}

/// Providers pour le profil
final profileControllerProvider = StateNotifierProvider<ProfileController, ProfileState>((ref) {
  return ProfileController();
});

final currentProfileProvider = Provider<UserProfile?>((ref) {
  return ref.watch(profileControllerProvider).profile;
});

final currentStationProvider = Provider<UserStationStatus?>((ref) {
  return ref.watch(profileControllerProvider).currentStation;
});

final profilePhotoUrlsProvider = Provider<Map<String, String>>((ref) {
  return ref.watch(profileControllerProvider).photoUrls;
});

final isProfileLoadingProvider = Provider<bool>((ref) {
  return ref.watch(profileControllerProvider).isLoading;
});
