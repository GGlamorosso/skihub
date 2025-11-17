import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppLocalizations {
  static const List<Locale> supportedLocales = [
    Locale('en', 'US'),
    Locale('fr', 'FR'),
  ];

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  // Common
  String get appName => _getValue('app_name');
  String get ok => _getValue('ok');
  String get cancel => _getValue('cancel');
  String get save => _getValue('save');
  String get delete => _getValue('delete');
  String get edit => _getValue('edit');
  String get retry => _getValue('retry');
  String get loading => _getValue('loading');
  String get error => _getValue('error');

  // Navigation
  String get matches => _getValue('matches');
  String get chat => _getValue('chat');
  String get profile => _getValue('profile');
  String get tracking => _getValue('tracking');
  String get premium => _getValue('premium');

  // Matching
  String get noMoreProfiles => _getValue('no_more_profiles');
  String get newMatch => _getValue('new_match');
  String get itsAMatch => _getValue('its_a_match');
  String get swipeToLike => _getValue('swipe_to_like');

  // Chat
  String get typeMessage => _getValue('type_message');
  String get sendMessage => _getValue('send_message');
  String get messageBlocked => _getValue('message_blocked');
  String get messageUnderReview => _getValue('message_under_review');

  // Premium
  String get becomePremium => _getValue('become_premium');
  String get unlimitedSwipes => _getValue('unlimited_swipes');
  String get unlimitedMessages => _getValue('unlimited_messages');
  String get seeWhoLikedYou => _getValue('see_who_liked_you');
  String get quotaLimitReached => _getValue('quota_limit_reached');

  // Privacy
  String get privacySettings => _getValue('privacy_settings');
  String get invisibleMode => _getValue('invisible_mode');
  String get hideAge => _getValue('hide_age');
  String get hideLevel => _getValue('hide_level');
  String get consentManagement => _getValue('consent_management');

  // Verification
  String get verifyIdentity => _getValue('verify_identity');
  String get videoVerification => _getValue('video_verification');
  String get verificationPending => _getValue('verification_pending');
  String get verificationApproved => _getValue('verification_approved');
  String get verificationRejected => _getValue('verification_rejected');

  // AI
  String get aiAssistant => _getValue('ai_assistant');
  String get aiSuggestion => _getValue('ai_suggestion');
  String get generateSuggestion => _getValue('generate_suggestion');
  String get useSuggestion => _getValue('use_suggestion');

  // Tracking
  String get startTracking => _getValue('start_tracking');
  String get stopTracking => _getValue('stop_tracking');
  String get trackingSession => _getValue('tracking_session');
  String get distance => _getValue('distance');
  String get maxSpeed => _getValue('max_speed');
  String get elevationGain => _getValue('elevation_gain');

  // Notifications
  String get notifications => _getValue('notifications');
  String get pushNotifications => _getValue('push_notifications');
  String get emailNotifications => _getValue('email_notifications');
  String get marketingNotifications => _getValue('marketing_notifications');

  // Errors
  String get networkError => _getValue('network_error');
  String get serverError => _getValue('server_error');
  String get permissionDenied => _getValue('permission_denied');
  String get cameraNotAvailable => _getValue('camera_not_available');

  // Date formatting
  String formatDate(DateTime date) {
    return DateFormat.yMMMd(locale.languageCode).format(date);
  }

  String formatTime(DateTime time) {
    return DateFormat.Hm(locale.languageCode).format(time);
  }

  String formatDateTime(DateTime dateTime) {
    return DateFormat.yMMMd(locale.languageCode).add_Hm().format(dateTime);
  }

  String formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return _getValue('just_now');
    } else if (difference.inHours < 1) {
      return _getValue('minutes_ago').replaceAll('{count}', '${difference.inMinutes}');
    } else if (difference.inDays < 1) {
      return _getValue('hours_ago').replaceAll('{count}', '${difference.inHours}');
    } else if (difference.inDays < 7) {
      return _getValue('days_ago').replaceAll('{count}', '${difference.inDays}');
    } else {
      return formatDate(dateTime);
    }
  }

  String _getValue(String key) {
    final translations = _getTranslations();
    return translations[key] ?? key;
  }

  Map<String, String> _getTranslations() {
    switch (locale.languageCode) {
      case 'fr':
        return _frenchTranslations;
      case 'en':
      default:
        return _englishTranslations;
    }
  }

  static const Map<String, String> _englishTranslations = {
    // Common
    'app_name': 'CrewSnow',
    'ok': 'OK',
    'cancel': 'Cancel',
    'save': 'Save',
    'delete': 'Delete',
    'edit': 'Edit',
    'retry': 'Retry',
    'loading': 'Loading...',
    'error': 'Error',

    // Navigation
    'matches': 'Matches',
    'chat': 'Chat',
    'profile': 'Profile',
    'tracking': 'Tracking',
    'premium': 'Premium',

    // Matching
    'no_more_profiles': 'No more profiles',
    'new_match': 'New Match!',
    'its_a_match': 'It\'s a Match!',
    'swipe_to_like': 'Swipe right to like',

    // Chat
    'type_message': 'Type a message...',
    'send_message': 'Send',
    'message_blocked': 'Message blocked',
    'message_under_review': 'Under review',

    // Premium
    'become_premium': 'Become Premium',
    'unlimited_swipes': 'Unlimited swipes',
    'unlimited_messages': 'Unlimited messages',
    'see_who_liked_you': 'See who liked you',
    'quota_limit_reached': 'Daily limit reached',

    // Privacy
    'privacy_settings': 'Privacy Settings',
    'invisible_mode': 'Invisible mode',
    'hide_age': 'Hide age',
    'hide_level': 'Hide level',
    'consent_management': 'Consent Management',

    // Verification
    'verify_identity': 'Verify Identity',
    'video_verification': 'Video Verification',
    'verification_pending': 'Verification pending',
    'verification_approved': 'Verified',
    'verification_rejected': 'Verification rejected',

    // AI
    'ai_assistant': 'AI Assistant',
    'ai_suggestion': 'AI Suggestion',
    'generate_suggestion': 'Generate Suggestion',
    'use_suggestion': 'Use Suggestion',

    // Tracking
    'start_tracking': 'Start Tracking',
    'stop_tracking': 'Stop Tracking',
    'tracking_session': 'Tracking Session',
    'distance': 'Distance',
    'max_speed': 'Max Speed',
    'elevation_gain': 'Elevation Gain',

    // Notifications
    'notifications': 'Notifications',
    'push_notifications': 'Push Notifications',
    'email_notifications': 'Email Notifications',
    'marketing_notifications': 'Marketing',

    // Time
    'just_now': 'Just now',
    'minutes_ago': '{count} min ago',
    'hours_ago': '{count}h ago',
    'days_ago': '{count}d ago',

    // Errors
    'network_error': 'Network connection error',
    'server_error': 'Server error occurred',
    'permission_denied': 'Permission denied',
    'camera_not_available': 'Camera not available',
  };

  static const Map<String, String> _frenchTranslations = {
    // Common
    'app_name': 'CrewSnow',
    'ok': 'OK',
    'cancel': 'Annuler',
    'save': 'Sauvegarder',
    'delete': 'Supprimer',
    'edit': 'Modifier',
    'retry': 'Réessayer',
    'loading': 'Chargement...',
    'error': 'Erreur',

    // Navigation  
    'matches': 'Matchs',
    'chat': 'Chat',
    'profile': 'Profil',
    'tracking': 'Tracking',
    'premium': 'Premium',

    // Matching
    'no_more_profiles': 'Plus de profils',
    'new_match': 'Nouveau Match !',
    'its_a_match': 'C\'est un Match !',
    'swipe_to_like': 'Swipez à droite pour liker',

    // Chat
    'type_message': 'Tapez votre message...',
    'send_message': 'Envoyer',
    'message_blocked': 'Message bloqué',
    'message_under_review': 'En révision',

    // Premium
    'become_premium': 'Devenir Premium',
    'unlimited_swipes': 'Swipes illimités',
    'unlimited_messages': 'Messages illimités',
    'see_who_liked_you': 'Voir qui vous a liké',
    'quota_limit_reached': 'Limite quotidienne atteinte',

    // Privacy
    'privacy_settings': 'Paramètres de confidentialité',
    'invisible_mode': 'Mode invisible',
    'hide_age': 'Masquer l\'âge',
    'hide_level': 'Masquer le niveau',
    'consent_management': 'Gestion des consentements',

    // Verification
    'verify_identity': 'Vérifier l\'identité',
    'video_verification': 'Vérification vidéo',
    'verification_pending': 'Vérification en cours',
    'verification_approved': 'Vérifié',
    'verification_rejected': 'Vérification rejetée',

    // AI
    'ai_assistant': 'Assistant IA',
    'ai_suggestion': 'Suggestion IA',
    'generate_suggestion': 'Générer une suggestion',
    'use_suggestion': 'Utiliser la suggestion',

    // Tracking
    'start_tracking': 'Démarrer le tracking',
    'stop_tracking': 'Arrêter le tracking',
    'tracking_session': 'Session de tracking',
    'distance': 'Distance',
    'max_speed': 'Vitesse max',
    'elevation_gain': 'Dénivelé positif',

    // Notifications
    'notifications': 'Notifications',
    'push_notifications': 'Notifications push',
    'email_notifications': 'Notifications email',
    'marketing_notifications': 'Marketing',

    // Time
    'just_now': 'À l\'instant',
    'minutes_ago': 'Il y a {count} min',
    'hours_ago': 'Il y a {count}h',
    'days_ago': 'Il y a {count}j',

    // Errors
    'network_error': 'Erreur de connexion réseau',
    'server_error': 'Erreur serveur',
    'permission_denied': 'Permission refusée',
    'camera_not_available': 'Caméra non disponible',
  };
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales.contains(locale);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(LocalizationsDelegate<AppLocalizations> old) => false;
}
