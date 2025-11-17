import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user_profile.dart';

/// Gestionnaire de session et persistance locale
class SessionManager {
  static SessionManager? _instance;
  static SessionManager get instance => _instance ??= SessionManager._();
  
  SessionManager._();
  
  static const String _keyLastUser = 'last_user_profile';
  static const String _keyOnboardingData = 'onboarding_data';
  static const String _keyAppSettings = 'app_settings';
  
  /// Sauvegarder profil utilisateur localement
  Future<void> saveUserProfile(UserProfile profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(profile.toJson());
      await prefs.setString(_keyLastUser, json);
    } catch (e) {
      print('Error saving user profile: $e');
    }
  }
  
  /// Récupérer profil utilisateur sauvegardé
  Future<UserProfile?> getLastUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_keyLastUser);
      
      if (json != null) {
        final Map<String, dynamic> data = jsonDecode(json);
        return UserProfile.fromJson(data);
      }
      
      return null;
    } catch (e) {
      print('Error loading user profile: $e');
      return null;
    }
  }
  
  /// Supprimer profil sauvegardé (logout)
  Future<void> clearUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyLastUser);
    } catch (e) {
      print('Error clearing user profile: $e');
    }
  }
  
  /// Sauvegarder données onboarding en cours
  Future<void> saveOnboardingProgress(Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(data);
      await prefs.setString(_keyOnboardingData, json);
    } catch (e) {
      print('Error saving onboarding data: $e');
    }
  }
  
  /// Récupérer données onboarding
  Future<Map<String, dynamic>?> getOnboardingProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_keyOnboardingData);
      
      if (json != null) {
        return jsonDecode(json) as Map<String, dynamic>;
      }
      
      return null;
    } catch (e) {
      print('Error loading onboarding data: $e');
      return null;
    }
  }
  
  /// Supprimer données onboarding (après completion)
  Future<void> clearOnboardingProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyOnboardingData);
    } catch (e) {
      print('Error clearing onboarding data: $e');
    }
  }
  
  /// Sauvegarder paramètres app
  Future<void> saveAppSettings(Map<String, dynamic> settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(settings);
      await prefs.setString(_keyAppSettings, json);
    } catch (e) {
      print('Error saving app settings: $e');
    }
  }
  
  /// Récupérer paramètres app
  Future<Map<String, dynamic>> getAppSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_keyAppSettings);
      
      if (json != null) {
        return jsonDecode(json) as Map<String, dynamic>;
      }
      
      return <String, dynamic>{};
    } catch (e) {
      print('Error loading app settings: $e');
      return <String, dynamic>{};
    }
  }
  
  /// Sauvegarder flag simple
  Future<void> setBool(String key, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, value);
    } catch (e) {
      print('Error setting bool: $e');
    }
  }
  
  /// Récupérer flag simple
  Future<bool> getBool(String key, {bool defaultValue = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(key) ?? defaultValue;
    } catch (e) {
      print('Error getting bool: $e');
      return defaultValue;
    }
  }
  
  /// Sauvegarder string
  Future<void> setString(String key, String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
    } catch (e) {
      print('Error setting string: $e');
    }
  }
  
  /// Récupérer string
  Future<String?> getString(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(key);
    } catch (e) {
      print('Error getting string: $e');
      return null;
    }
  }
  
  /// Clear toutes les données
  Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (e) {
      print('Error clearing all data: $e');
    }
  }
}
