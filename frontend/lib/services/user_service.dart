import 'package:flutter/foundation.dart';
import '../models/user_profile.dart';
import '../models/station.dart';
import 'supabase_service.dart';

/// Service pour gestion des profils utilisateurs
class UserService {
  static UserService? _instance;
  static UserService get instance => _instance ??= UserService._();
  
  UserService._();
  
  final _supabase = SupabaseService.instance;
  
  /// Récupérer profil utilisateur complet
  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      final response = await _supabase.from('users')
          .select('''
            *,
            profile_photos!profile_photos_user_id_fkey(
              storage_path,
              is_main,
              moderation_status
            ),
            user_station_status(
              station_id,
              date_from,
              date_to,
              radius_km,
              is_active,
              stations(name, country_code, region)
            )
          ''')
          .eq('id', userId)
          .maybeSingle(); // Use maybeSingle() instead of single() to handle 0 rows
      
      if (response == null) {
        debugPrint('No profile found for user $userId');
        return null;
      }
      
      return UserProfile.fromJson(response);
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
      return null;
    }
  }
  
  /// Mettre à jour profil utilisateur
  Future<bool> updateUserProfile({
    required String userId,
    String? username,
    String? bio,
    DateTime? birthDate,
    UserLevel? level,
    List<RideStyle>? rideStyles,
    List<String>? languages,
    List<String>? objectives,
    bool? onboardingCompleted,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      if (username != null) updateData['username'] = username;
      if (bio != null) updateData['bio'] = bio;
      if (birthDate != null) updateData['birth_date'] = birthDate.toIso8601String();
      if (level != null) updateData['level'] = level.name;
      if (rideStyles != null) updateData['ride_styles'] = rideStyles.map((e) => e.name).toList();
      if (languages != null) updateData['languages'] = languages;
      if (objectives != null) updateData['objectives'] = objectives;
      if (onboardingCompleted != null) updateData['onboarding_completed'] = onboardingCompleted;
      
      await _supabase.from('users')
          .update(updateData)
          .eq('id', userId);
      
      return true;
    } catch (e) {
      debugPrint('Error updating user profile: $e');
      return false;
    }
  }
  
  /// Uploader une photo de profil
  Future<String?> uploadProfilePhoto({
    required String userId,
    required List<int> photoBytes,
    bool isMain = false,
  }) async {
    try {
      final fileName = '${userId}_${isMain ? 'main' : 'additional'}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = 'profile_photos/$userId/$fileName';
      
      await _supabase.uploadFile(
        bucket: 'profile_photos',
        path: path,
        bytes: photoBytes,
        metadata: {
          'user_id': userId,
          'is_main': isMain.toString(),
        },
      );
      
      // Insérer dans table profile_photos
      await _supabase.from('profile_photos').insert({
        'user_id': userId,
        'storage_path': path,
        'is_main': isMain,
        'moderation_status': 'pending',
      });
      
      return path;
    } catch (e) {
      debugPrint('Error uploading profile photo: $e');
      return null;
    }
  }
  
  /// Créer/mettre à jour station status
  Future<bool> updateStationStatus({
    required String userId,
    required String stationId,
    required DateTime dateFrom,
    required DateTime dateTo,
    required int radiusKm,
  }) async {
    try {
      // Désactiver anciens statuts
      await _supabase.from('user_station_status')
          .update({'is_active': false})
          .eq('user_id', userId);
      
      // Créer nouveau statut
      await _supabase.from('user_station_status').insert({
        'user_id': userId,
        'station_id': stationId,
        'date_from': dateFrom.toIso8601String(),
        'date_to': dateTo.toIso8601String(),
        'radius_km': radiusKm,
        'is_active': true,
      });
      
      return true;
    } catch (e) {
      debugPrint('Error updating station status: $e');
      return false;
    }
  }
  
  /// Récupérer stations disponibles
  Future<List<Station>> getStations({String? searchTerm}) async {
    try {
      var query = _supabase.from('stations')
          .select()
          .eq('is_active', true)
          .order('name');
      
      // TODO: Implémenter recherche case-insensitive (ilike non disponible dans cette version de Supabase)
      // if (searchTerm != null && searchTerm.isNotEmpty) {
      //   query = query.ilike('name', '%$searchTerm%');
      // }
      
      final response = await query.limit(50);
      
      return (response as List)
          .map((json) => Station.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error fetching stations: $e');
      return [];
    }
  }
  
  /// Vérifier si onboarding est complet
  Future<bool> isOnboardingComplete(String userId) async {
    try {
      final response = await _supabase.from('users')
          .select('onboarding_completed')
          .eq('id', userId)
          .single();
      
      return response['onboarding_completed'] == true;
    } catch (e) {
      debugPrint('Error checking onboarding status: $e');
      return false;
    }
  }
  
  /// Obtenir URL signée pour photo
  Future<String?> getProfilePhotoUrl({
    required String storagePath,
    int expiresIn = 3600,
  }) async {
    try {
      return await _supabase.getSignedUrl(
        bucket: 'profile_photos',
        path: storagePath,
        expiresIn: expiresIn,
      );
    } catch (e) {
      debugPrint('Error getting photo URL: $e');
      return null;
    }
  }
  
  /// Supprimer photo de profil
  Future<bool> deleteProfilePhoto({
    required String userId,
    required String storagePath,
  }) async {
    try {
      // Supprimer de storage
      await _supabase.storage.from('profile_photos').remove([storagePath]);
      
      // Supprimer de la table
      await _supabase.from('profile_photos')
          .delete()
          .eq('user_id', userId)
          .eq('storage_path', storagePath);
      
      return true;
    } catch (e) {
      debugPrint('Error deleting profile photo: $e');
      return false;
    }
  }
}
