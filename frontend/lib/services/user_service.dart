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
        // ✅ Si le profil n'existe pas dans public.users, essayer de récupérer l'email depuis auth.users
        try {
          final authUser = _supabase.currentUser;
          if (authUser?.email != null) {
            debugPrint('⚠️ Profile not found in public.users, but user exists in auth.users');
            // Le profil sera créé lors de l'onboarding ou par gatekeeper
          }
        } catch (e) {
          debugPrint('Error checking auth user: $e');
        }
        return null;
      }
      
      // ✅ Corrigé : Convertir NULL arrays en tableaux vides pour éviter type cast errors
      // + Convertir snake_case vers camelCase pour le modèle
      final cleanedResponse = Map<String, dynamic>.from(response);
      
      // ✅ Si l'email n'est pas dans la réponse, le récupérer depuis auth.users
      if (cleanedResponse['email'] == null || cleanedResponse['email'] == '') {
        try {
          final authUser = _supabase.currentUser;
          if (authUser?.email != null) {
            cleanedResponse['email'] = authUser!.email!;
            debugPrint('✅ Email récupéré depuis auth.users');
          }
        } catch (e) {
          debugPrint('Error getting email from auth: $e');
        }
      }
      
      // Convertir snake_case vers camelCase
      cleanedResponse['rideStyles'] = cleanedResponse['ride_styles'] ?? [];
      cleanedResponse['languages'] = cleanedResponse['languages'] ?? [];
      cleanedResponse['objectives'] = cleanedResponse['objectives'] ?? [];
      cleanedResponse['isPremium'] = cleanedResponse['is_premium'] ?? false;
      cleanedResponse['premiumExpiresAt'] = cleanedResponse['premium_expires_at'];
      cleanedResponse['birthDate'] = cleanedResponse['birth_date'];
      cleanedResponse['lastActiveAt'] = cleanedResponse['last_active_at'];
      cleanedResponse['createdAt'] = cleanedResponse['created_at'];
      cleanedResponse['verificationStatus'] = cleanedResponse['verified_video_status'] ?? 'not_submitted';
      
      // Supprimer les clés snake_case pour éviter confusion
      cleanedResponse.remove('ride_styles');
      cleanedResponse.remove('is_premium');
      cleanedResponse.remove('premium_expires_at');
      cleanedResponse.remove('birth_date');
      cleanedResponse.remove('last_active_at');
      cleanedResponse.remove('created_at');
      cleanedResponse.remove('verified_video_status');
      
      return UserProfile.fromJson(cleanedResponse);
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
  /// ✅ Corrigé : Utilise upsert pour éviter les erreurs de contrainte unique
  Future<bool> updateStationStatus({
    required String userId,
    required String stationId,
    required DateTime dateFrom,
    required DateTime dateTo,
    required int radiusKm,
  }) async {
    try {
      // 1) Désactiver toutes les anciennes stations actives de l'utilisateur
      await _supabase.from('user_station_status')
          .update({'is_active': false})
          .eq('user_id', userId);
      
      // 2) Vérifier si une entrée existe déjà pour cette combinaison user_id + station_id
      final existing = await _supabase.from('user_station_status')
          .select('id')
          .eq('user_id', userId)
          .eq('station_id', stationId)
          .maybeSingle();
      
      if (existing != null) {
        // Mettre à jour l'entrée existante
        await _supabase.from('user_station_status')
            .update({
              'date_from': dateFrom.toIso8601String(),
              'date_to': dateTo.toIso8601String(),
              'radius_km': radiusKm,
              'is_active': true,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', existing['id']);
      } else {
        // Créer une nouvelle entrée
        await _supabase.from('user_station_status').insert({
          'user_id': userId,
          'station_id': stationId,
          'date_from': dateFrom.toIso8601String(),
          'date_to': dateTo.toIso8601String(),
          'radius_km': radiusKm,
          'is_active': true,
        });
      }
      
      return true;
    } catch (e) {
      debugPrint('Error updating station status: $e');
      return false;
    }
  }
  
  /// Récupérer stations disponibles
  Future<List<Station>> getStations({String? searchTerm}) async {
    try {
      debugPrint('🔍 Fetching stations, searchTerm: $searchTerm');
      
      var query = _supabase.from('stations')
          .select()
          .eq('is_active', true)
          .order('name');
      
      // ✅ Corrigé : Recherche (filtrage côté client car ilike peut ne pas être disponible)
      final response = await query.limit(200); // Augmenter la limite
      
      debugPrint('📊 Stations response: ${response.length} stations found');
      
      if (response.isEmpty) {
        debugPrint('⚠️ No stations found in database');
        return [];
      }
      
      // ✅ Corrigé : Convertir snake_case vers camelCase et filtrer si searchTerm fourni
      final List<Station> stations = [];
      final searchLower = searchTerm?.toLowerCase() ?? '';
      
      for (final item in response) {
        // Filtrer côté client si searchTerm fourni
        if (searchLower.isNotEmpty) {
          final name = (item['name'] as String? ?? '').toLowerCase();
          final region = (item['region'] as String? ?? '').toLowerCase();
          final countryCode = (item['country_code'] as String? ?? '').toLowerCase();
          
          if (!name.contains(searchLower) && 
              !region.contains(searchLower) && 
              !countryCode.contains(searchLower)) {
            continue; // Skip cette station
          }
        }
        try {
          final cleanedItem = Map<String, dynamic>.from(item);
          
          // ✅ Vérifier que les champs requis existent
          if (cleanedItem['id'] == null || cleanedItem['name'] == null) {
            debugPrint('⚠️ Station missing required fields: $item');
            continue;
          }
          
          // Convertir snake_case vers camelCase (avec gestion des nulls)
          cleanedItem['countryCode'] = cleanedItem['country_code'] ?? '';
          cleanedItem['region'] = cleanedItem['region'] ?? '';
          cleanedItem['elevationM'] = cleanedItem['elevation_m'] ?? 0;
          cleanedItem['officialWebsite'] = cleanedItem['official_website'];
          cleanedItem['seasonStartMonth'] = cleanedItem['season_start_month'] ?? 12;
          cleanedItem['seasonEndMonth'] = cleanedItem['season_end_month'] ?? 3;
          cleanedItem['isActive'] = cleanedItem['is_active'] ?? true;
          cleanedItem['createdAt'] = cleanedItem['created_at'] ?? DateTime.now().toIso8601String();
          
          // Vérifier latitude/longitude
          if (cleanedItem['latitude'] == null || cleanedItem['longitude'] == null) {
            debugPrint('⚠️ Station missing coordinates: ${cleanedItem['name']}');
            continue;
          }
          
          // Supprimer les clés snake_case
          cleanedItem.remove('country_code');
          cleanedItem.remove('elevation_m');
          cleanedItem.remove('official_website');
          cleanedItem.remove('season_start_month');
          cleanedItem.remove('season_end_month');
          cleanedItem.remove('is_active');
          cleanedItem.remove('created_at');
          
          stations.add(Station.fromJson(cleanedItem));
        } catch (e, stackTrace) {
          debugPrint('❌ Error parsing station: $e');
          debugPrint('   Data: $item');
          debugPrint('   Stack: $stackTrace');
          // Continuer avec les autres stations
        }
      }
      
      debugPrint('✅ Successfully parsed ${stations.length} stations');
      return stations;
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
