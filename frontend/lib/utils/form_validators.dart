import 'dart:io';
import '../utils/constants.dart';

/// Validateurs de formulaires pour CrewSnow
class FormValidators {
  /// Validation email
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'L\'email est obligatoire';
    }
    
    if (!ValidationRegex.email.hasMatch(value)) {
      return 'Format d\'email invalide';
    }
    
    return null;
  }
  
  /// Validation mot de passe
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le mot de passe est obligatoire';
    }
    
    if (value.length < 8) {
      return 'Au moins 8 caractères requis';
    }
    
    if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)').hasMatch(value)) {
      return 'Doit contenir: minuscule, majuscule, chiffre';
    }
    
    return null;
  }
  
  /// Validation confirmation mot de passe
  static String? confirmPassword(String? value, String originalPassword) {
    if (value == null || value.isEmpty) {
      return 'Confirmation obligatoire';
    }
    
    if (value != originalPassword) {
      return 'Les mots de passe ne correspondent pas';
    }
    
    return null;
  }
  
  /// Validation prénom
  static String? firstName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le prénom est obligatoire';
    }
    
    if (value.trim().length < 2) {
      return 'Au moins 2 caractères';
    }
    
    if (value.trim().length > AppConstants.maxUsernameLength) {
      return 'Maximum ${AppConstants.maxUsernameLength} caractères';
    }
    
    if (!RegExp(r"^[a-zA-ZÀ-ÿ\s\-']+$").hasMatch(value)) {
      return 'Caractères invalides';
    }
    
    return null;
  }
  
  /// Validation nom (optionnel)
  static String? lastName(String? value) {
    if (value != null && value.isNotEmpty) {
      if (value.trim().length > 50) {
        return 'Maximum 50 caractères';
      }
      
      if (!RegExp(r"^[a-zA-ZÀ-ÿ\s\-']+$").hasMatch(value)) {
        return 'Caractères invalides';
      }
    }
    
    return null;
  }
  
  /// Validation âge
  static String? age(String? value) {
    if (value == null || value.isEmpty) {
      return 'L\'âge est obligatoire';
    }
    
    final age = int.tryParse(value);
    if (age == null) {
      return 'Âge invalide';
    }
    
    if (age < AppConstants.minAge) {
      return 'Tu dois avoir au moins ${AppConstants.minAge} ans';
    }
    
    if (age > AppConstants.maxAge) {
      return 'Âge maximum ${AppConstants.maxAge} ans';
    }
    
    return null;
  }
  
  /// Validation username
  static String? username(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le nom d\'utilisateur est obligatoire';
    }
    
    if (value.length < 3) {
      return 'Au moins 3 caractères';
    }
    
    if (value.length > AppConstants.maxUsernameLength) {
      return 'Maximum ${AppConstants.maxUsernameLength} caractères';
    }
    
    if (!ValidationRegex.username.hasMatch(value)) {
      return 'Lettres, chiffres et _ uniquement';
    }
    
    return null;
  }
  
  /// Validation bio
  static String? bio(String? value) {
    if (value != null && value.length > AppConstants.maxBioLength) {
      return 'Maximum ${AppConstants.maxBioLength} caractères';
    }
    
    return null;
  }
  
  /// Validation rayon de recherche
  static String? searchRadius(int? value) {
    if (value == null) {
      return 'Le rayon est obligatoire';
    }
    
    if (value < 5) {
      return 'Rayon minimum 5 km';
    }
    
    if (value > 100) {
      return 'Rayon maximum 100 km';
    }
    
    return null;
  }
  
  /// Validation dates de séjour
  static String? dateRange(DateTime? startDate, DateTime? endDate) {
    if (startDate == null || endDate == null) {
      return 'Les dates sont obligatoires';
    }
    
    if (startDate.isAfter(endDate)) {
      return 'La date de début doit être avant la fin';
    }
    
    final now = DateTime.now();
    if (endDate.isBefore(now.subtract(const Duration(days: 1)))) {
      return 'Les dates ne peuvent pas être dans le passé';
    }
    
    final duration = endDate.difference(startDate).inDays;
    if (duration > 365) {
      return 'Séjour maximum 1 an';
    }
    
    return null;
  }
  
  /// Validation liste non vide
  static String? nonEmptyList(List? list, String fieldName) {
    if (list == null || list.isEmpty) {
      return '$fieldName requis';
    }
    
    return null;
  }
  
  /// Validation fichier image
  static String? imageFile(File? file) {
    if (file == null) {
      return 'Une photo est requise';
    }
    
    final extension = file.path.split('.').last.toLowerCase();
    final allowedExtensions = ['jpg', 'jpeg', 'png', 'webp'];
    
    if (!allowedExtensions.contains(extension)) {
      return 'Format non supporté (JPG, PNG, WebP)';
    }
    
    return null;
  }
}
