import 'package:freezed_annotation/freezed_annotation.dart';

part 'consent.freezed.dart';
part 'consent.g.dart';

@freezed
class Consent with _$Consent {
  const factory Consent({
    required String id,
    required String userId,
    required String purpose,
    required int version,
    required bool granted,
    DateTime? grantedAt,
    DateTime? revokedAt,
    String? ipAddress,
    String? userAgent,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Consent;

  factory Consent.fromJson(Map<String, dynamic> json) =>
      _$ConsentFromJson(json);

  const Consent._();

  bool get isActive => granted && grantedAt != null;
  bool get wasRevoked => !granted && revokedAt != null;
  
  String get statusDisplay {
    if (isActive) return 'Accordé';
    if (wasRevoked) return 'Révoqué';
    return 'Non accordé';
  }

  String get purposeDisplay {
    switch (purpose) {
      case 'gps_tracking':
        return 'Suivi GPS';
      case 'ai_moderation':
        return 'Modération IA';
      case 'ai_assistance':
        return 'Assistant IA';
      case 'marketing':
        return 'Communications marketing';
      case 'analytics':
        return 'Analyses d\'usage';
      case 'photo_analysis':
        return 'Analyse photos IA';
      case 'location_sharing':
        return 'Partage localisation';
      case 'data_export':
        return 'Export de données';
      default:
        return purpose;
    }
  }

  String get description {
    switch (purpose) {
      case 'gps_tracking':
        return 'Permet le suivi de votre localisation pour le matching géographique et les statistiques de ski';
      case 'ai_moderation':
        return 'Utilise l\'IA pour modérer automatiquement les messages et détecter le contenu inapproprié';
      case 'ai_assistance':
        return 'Active l\'assistant IA pour les suggestions de messages et aide à la conversation';
      case 'marketing':
        return 'Autorise l\'envoi de communications promotionnelles et offres spéciales';
      case 'analytics':
        return 'Collecte des données d\'usage anonymisées pour améliorer l\'application';
      case 'photo_analysis':
        return 'Analyse automatique des photos pour la modération et suggestions de profil';
      case 'location_sharing':
        return 'Partage votre localisation approximative avec les autres utilisateurs';
      case 'data_export':
        return 'Permet l\'export de vos données personnelles sur demande';
      default:
        return 'Consentement pour $purpose';
    }
  }

  bool get isRequired {
    switch (purpose) {
      case 'gps_tracking':
      case 'location_sharing':
        return true; // Required for core app functionality
      default:
        return false;
    }
  }

  IconData get icon {
    switch (purpose) {
      case 'gps_tracking':
        return Icons.location_on;
      case 'ai_moderation':
        return Icons.security;
      case 'ai_assistance':
        return Icons.smart_toy;
      case 'marketing':
        return Icons.email;
      case 'analytics':
        return Icons.analytics;
      case 'photo_analysis':
        return Icons.photo_camera;
      case 'location_sharing':
        return Icons.share_location;
      case 'data_export':
        return Icons.download;
      default:
        return Icons.privacy_tip;
    }
  }
}

@freezed
class PrivacySettings with _$PrivacySettings {
  const factory PrivacySettings({
    required bool isInvisible,
    required bool hideAge,
    required bool hideLevel,
    required bool hideStats,
    required bool hideLastActive,
    required bool notificationsPush,
    required bool notificationsEmail,
    required bool notificationsMarketing,
  }) = _PrivacySettings;

  factory PrivacySettings.fromJson(Map<String, dynamic> json) =>
      _$PrivacySettingsFromJson(json);

  const PrivacySettings._();

  Map<String, bool> toMap() => {
    'is_invisible': isInvisible,
    'hide_age': hideAge,
    'hide_level': hideLevel,
    'hide_stats': hideStats,
    'hide_last_active': hideLastActive,
    'notifications_push': notificationsPush,
    'notifications_email': notificationsEmail,
    'notifications_marketing': notificationsMarketing,
  };
}

@freezed
class VerificationRequest with _$VerificationRequest {
  const factory VerificationRequest({
    required String id,
    required String userId,
    required String videoStoragePath,
    int? videoDurationSeconds,
    int? videoSizeBytes,
    required String status,
    required DateTime submittedAt,
    DateTime? reviewedAt,
    String? reviewerId,
    String? rejectionReason,
    double? verificationScore,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _VerificationRequest;

  factory VerificationRequest.fromJson(Map<String, dynamic> json) =>
      _$VerificationRequestFromJson(json);

  const VerificationRequest._();

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
  bool get isExpired => status == 'expired';

  String get statusDisplay {
    switch (status) {
      case 'pending':
        return 'En cours de vérification';
      case 'approved':
        return 'Vérifié';
      case 'rejected':
        return 'Rejeté';
      case 'expired':
        return 'Expiré';
      default:
        return status;
    }
  }

  Color get statusColor {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'expired':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  bool get canRetry => isRejected || isExpired;

  String get durationDisplay {
    if (videoDurationSeconds == null) return 'N/A';
    final duration = Duration(seconds: videoDurationSeconds!);
    return '${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';
  }

  String get sizeDisplay {
    if (videoSizeBytes == null) return 'N/A';
    final mb = videoSizeBytes! / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }
}

@freezed
class AIInteraction with _$AIInteraction {
  const factory AIInteraction({
    required String id,
    required String userId,
    String? matchId,
    required String interactionType,
    String? promptUsed,
    String? aiResponse,
    required bool wasUsed,
    DateTime? usedAt,
    int? userRating,
    String? feedbackText,
    required DateTime createdAt,
  }) = _AIInteraction;

  factory AIInteraction.fromJson(Map<String, dynamic> json) =>
      _$AIInteractionFromJson(json);

  const AIInteraction._();

  String get typeDisplay {
    switch (interactionType) {
      case 'icebreaker':
        return 'Suggestion de premier message';
      case 'message_suggestion':
        return 'Suggestion de message';
      case 'profile_enhancement':
        return 'Amélioration de profil';
      case 'moderation_appeal':
        return 'Appel de modération';
      case 'safety_check':
        return 'Vérification sécurité';
      default:
        return interactionType;
    }
  }

  IconData get typeIcon {
    switch (interactionType) {
      case 'icebreaker':
        return Icons.chat_bubble_outline;
      case 'message_suggestion':
        return Icons.lightbulb_outline;
      case 'profile_enhancement':
        return Icons.auto_awesome;
      case 'moderation_appeal':
        return Icons.gavel;
      case 'safety_check':
        return Icons.security;
      default:
        return Icons.smart_toy;
    }
  }

  bool get hasRating => userRating != null;
  bool get hasBeenUsed => wasUsed && usedAt != null;
}
