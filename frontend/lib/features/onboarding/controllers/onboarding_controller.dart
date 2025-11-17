import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';

import '../../../models/user_profile.dart';
import '../../../models/station.dart';
import '../../../services/supabase_service.dart';

/// État des données d'onboarding
@immutable
class OnboardingData {
  const OnboardingData({
    this.firstName,
    this.lastName,
    this.age,
    this.birthDate,
    this.photoFile,
    this.photoUrl,
    this.level,
    this.rideStyles = const {},
    this.objectives = const {},
    this.languages = const {},
    this.station,
    this.dateFrom,
    this.dateTo,
    this.radiusKm,
    this.enableTracking = false,
    this.isComplete = false,
  });
  
  final String? firstName;
  final String? lastName;
  final int? age;
  final DateTime? birthDate;
  final File? photoFile;
  final String? photoUrl;
  final UserLevel? level;
  final Set<RideStyle> rideStyles;
  final Set<String> objectives;
  final Set<String> languages;
  final Station? station;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final int? radiusKm;
  final bool enableTracking;
  final bool isComplete;
  
  OnboardingData copyWith({
    String? firstName,
    String? lastName,
    int? age,
    DateTime? birthDate,
    File? photoFile,
    String? photoUrl,
    UserLevel? level,
    Set<RideStyle>? rideStyles,
    Set<String>? objectives,
    Set<String>? languages,
    Station? station,
    DateTime? dateFrom,
    DateTime? dateTo,
    int? radiusKm,
    bool? enableTracking,
    bool? isComplete,
  }) {
    return OnboardingData(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      age: age ?? this.age,
      birthDate: birthDate ?? this.birthDate,
      photoFile: photoFile ?? this.photoFile,
      photoUrl: photoUrl ?? this.photoUrl,
      level: level ?? this.level,
      rideStyles: rideStyles ?? this.rideStyles,
      objectives: objectives ?? this.objectives,
      languages: languages ?? this.languages,
      station: station ?? this.station,
      dateFrom: dateFrom ?? this.dateFrom,
      dateTo: dateTo ?? this.dateTo,
      radiusKm: radiusKm ?? this.radiusKm,
      enableTracking: enableTracking ?? this.enableTracking,
      isComplete: isComplete ?? this.isComplete,
    );
  }
  
  bool get hasRequiredFields => 
      firstName != null &&
      firstName!.isNotEmpty &&
      age != null &&
      photoFile != null &&
      level != null &&
      rideStyles.isNotEmpty &&
      languages.isNotEmpty;
}

/// Controller pour l'onboarding
class OnboardingController extends StateNotifier<OnboardingData> {
  OnboardingController() : super(const OnboardingData());
  
  final _supabase = SupabaseService.instance;
  
  /// Mettre à jour nom/prénom
  void updateName({String? firstName, String? lastName}) {
    state = state.copyWith(
      firstName: firstName,
      lastName: lastName,
    );
  }
  
  /// Mettre à jour âge
  void updateAge({int? age, DateTime? birthDate}) {
    state = state.copyWith(
      age: age,
      birthDate: birthDate,
    );
  }
  
  /// Mettre à jour photo
  void updatePhoto(File photoFile) {
    state = state.copyWith(
      photoFile: photoFile,
    );
  }
  
  /// Mettre à jour niveau
  void updateLevel(UserLevel level) {
    state = state.copyWith(level: level);
  }
  
  /// Mettre à jour styles de ride
  void updateRideStyles(Set<RideStyle> rideStyles) {
    state = state.copyWith(rideStyles: rideStyles);
  }
  
  /// Mettre à jour objectifs
  void updateObjectives(Set<String> objectives) {
    state = state.copyWith(objectives: objectives);
  }
  
  /// Mettre à jour langues
  void updateLanguages(Set<String> languages) {
    state = state.copyWith(languages: languages);
  }
  
  /// Mettre à jour station et dates
  void updateStationInfo({
    Station? station,
    DateTime? dateFrom,
    DateTime? dateTo,
    int? radiusKm,
  }) {
    state = state.copyWith(
      station: station,
      dateFrom: dateFrom,
      dateTo: dateTo,
      radiusKm: radiusKm,
    );
  }
  
  /// Mettre à jour tracking
  void updateTracking(bool enableTracking) {
    state = state.copyWith(enableTracking: enableTracking);
  }
  
  /// Finaliser l'onboarding - envoyer toutes les données vers Supabase
  Future<bool> completeOnboarding() async {
    try {
      if (!state.hasRequiredFields) {
        throw Exception('Certains champs obligatoires sont manquants');
      }
      
      final userId = _supabase.currentUserId!;
      
      // 1. Upload photo
      String? photoPath;
      if (state.photoFile != null) {
        final fileName = '${userId}_main_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final path = 'profile_photos/$userId/$fileName';
        
        final bytes = await state.photoFile!.readAsBytes();
        await _supabase.uploadFile(
          bucket: 'profile_photos',
          path: path,
          bytes: bytes,
          metadata: {
            'user_id': userId,
            'is_main': 'true',
          },
        );
        
        photoPath = path;
      }
      
      // 2. Mettre à jour ou créer profil utilisateur
      // Utiliser upsert pour créer si n'existe pas, ou mettre à jour si existe
      await _supabase.from('users').upsert({
        'id': userId,
        'username': _generateUsernameFromName(),
        'bio': _generateBioFromObjectives(),
        'birth_date': state.birthDate?.toIso8601String(),
        'level': state.level!.name,
        'ride_styles': state.rideStyles.map((e) => e.name).toList(),
        'languages': state.languages.toList(),
        'onboarding_completed': true,
        'updated_at': DateTime.now().toIso8601String(),
        'is_active': true,
        'last_active_at': DateTime.now().toIso8601String(),
      }, onConflict: 'id');
      
      // 3. Insérer photo si uploadée
      if (photoPath != null) {
        await _supabase.from('profile_photos').insert({
          'user_id': userId,
          'storage_path': photoPath,
          'is_main': true,
          'moderation_status': 'pending',
        });
      }
      
      // 4. Insérer station status si définie
      if (state.station != null && 
          state.dateFrom != null && 
          state.dateTo != null) {
        await _supabase.from('user_station_status').insert({
          'user_id': userId,
          'station_id': state.station!.id,
          'date_from': state.dateFrom!.toIso8601String(),
          'date_to': state.dateTo!.toIso8601String(),
          'radius_km': state.radiusKm ?? 25,
          'is_active': true,
        });
      }
      
      // 5. Gérer consents GPS
      if (state.enableTracking) {
        try {
          await _supabase.callFunction(
            functionName: 'manage-consent',
            body: {
              'action': 'grant',
              'purpose': 'gps_tracking',
              'version': 1,
            },
          );
        } catch (e) {
          debugPrint('Consent management error: $e');
          // Continue même si consent échoue
        }
      }
      
      // Marquer onboarding comme complet
      state = state.copyWith(isComplete: true);
      
      return true;
    } catch (e) {
      debugPrint('Onboarding completion error: $e');
      return false;
    }
  }
  
  String _generateUsernameFromName() {
    final firstName = state.firstName!.toLowerCase();
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString().substring(8);
    return '${firstName}_$timestamp';
  }
  
  String _generateBioFromObjectives() {
    if (state.objectives.isEmpty) return '';
    
    final objectives = state.objectives.take(2).join(', ');
    final level = state.level!.displayName;
    
    return '$level passionné de ski. $objectives. Toujours prêt pour de nouvelles aventures sur les pistes ! 🎿';
  }
  
  /// Reset l'onboarding
  void reset() {
    state = const OnboardingData();
  }
}

/// Provider pour le controller d'onboarding
final onboardingControllerProvider = StateNotifierProvider<OnboardingController, OnboardingData>((ref) {
  return OnboardingController();
});
