import 'package:supabase_flutter/supabase_flutter.dart';

/// Gestionnaire d'erreurs pour CrewSnow
class ErrorHandler {
  /// Convertir erreurs Supabase en messages user-friendly
  static String getReadableError(dynamic error) {
    if (error is AuthException) {
      return _getAuthErrorMessage(error);
    }
    
    if (error is PostgrestException) {
      return _getPostgrestErrorMessage(error);
    }
    
    if (error is StorageException) {
      return _getStorageErrorMessage(error);
    }
    
    // Erreurs réseau génériques
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('network') || errorString.contains('connection')) {
      return 'Problème de connexion. Vérifiez votre réseau.';
    }
    
    if (errorString.contains('timeout')) {
      return 'Délai d\'attente dépassé. Réessayez.';
    }
    
    if (errorString.contains('permission')) {
      return 'Permissions insuffisantes.';
    }
    
    // Erreur générique
    return 'Une erreur est survenue. Réessayez.';
  }
  
  static String _getAuthErrorMessage(AuthException error) {
    switch (error.message) {
      case 'Invalid login credentials':
        return 'Email ou mot de passe incorrect.';
      case 'Email not confirmed':
        return 'Veuillez confirmer votre email.';
      case 'User already registered':
        return 'Un compte existe déjà avec cet email.';
      case 'Password should be at least 6 characters':
        return 'Le mot de passe doit contenir au moins 6 caractères.';
      case 'Signup disabled':
        return 'Les inscriptions sont temporairement désactivées.';
      case 'Too many requests':
        return 'Trop de tentatives. Réessayez dans quelques minutes.';
      case 'Email rate limit exceeded':
        return 'Trop d\'emails envoyés. Attendez avant de réessayer.';
      default:
        return 'Erreur d\'authentification: ${error.message}';
    }
  }
  
  static String _getPostgrestErrorMessage(PostgrestException error) {
    final message = error.message.toLowerCase();
    
    if (message.contains('duplicate key') || message.contains('unique constraint')) {
      return 'Ces informations existent déjà.';
    }
    
    if (message.contains('foreign key constraint')) {
      return 'Référence invalide. Vérifiez vos données.';
    }
    
    if (message.contains('check constraint')) {
      return 'Données invalides. Vérifiez votre saisie.';
    }
    
    if (message.contains('not null constraint')) {
      return 'Certains champs obligatoires sont manquants.';
    }
    
    if (message.contains('permission denied') || message.contains('insufficient_privilege')) {
      return 'Vous n\'avez pas les droits pour cette action.';
    }
    
    if (error.code == 'PGRST116') {
      return 'Aucun résultat trouvé.';
    }
    
    return 'Erreur de base de données: ${error.message}';
  }
  
  static String _getStorageErrorMessage(StorageException error) {
    final message = error.message.toLowerCase();
    
    if (message.contains('file size') || message.contains('too large')) {
      return 'Fichier trop volumineux (max 5MB).';
    }
    
    if (message.contains('file type') || message.contains('invalid format')) {
      return 'Format de fichier non supporté.';
    }
    
    if (message.contains('not found')) {
      return 'Fichier non trouvé.';
    }
    
    if (message.contains('permission') || message.contains('access denied')) {
      return 'Accès refusé au fichier.';
    }
    
    if (message.contains('quota') || message.contains('storage limit')) {
      return 'Limite de stockage atteinte.';
    }
    
    return 'Erreur de stockage: ${error.message}';
  }
  
  /// Vérifier si erreur est récupérable (retry possible)
  static bool isRetryableError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    return errorString.contains('network') ||
           errorString.contains('connection') ||
           errorString.contains('timeout') ||
           errorString.contains('server error') ||
           errorString.contains('503') ||
           errorString.contains('502') ||
           errorString.contains('500');
  }
  
  /// Logger d'erreur avec contexte
  static void logError({
    required String context,
    required dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? additionalData,
  }) {
    final errorInfo = {
      'context': context,
      'error': error.toString(),
      'type': error.runtimeType.toString(),
      'timestamp': DateTime.now().toIso8601String(),
      if (additionalData != null) ...additionalData,
    };
    
    print('🔥 CrewSnow Error: $errorInfo');
    
    // TODO S8: Envoyer vers service de monitoring (Crashlytics/Sentry)
  }
}
