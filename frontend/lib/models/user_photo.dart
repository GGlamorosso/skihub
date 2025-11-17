import 'package:json_annotation/json_annotation.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

part 'user_photo.g.dart';

@JsonSerializable()
class UserPhoto {
  final String id;
  final String userId;
  final String storagePath;
  final bool isMain;
  final ModerationStatus moderationStatus;
  final String? moderationReason;
  final DateTime createdAt;
  final DateTime? updatedAt;
  
  // Données UI (non stockées en DB)
  final String? signedUrl;
  final bool isUploading;
  final double uploadProgress;
  
  const UserPhoto({
    required this.id,
    required this.userId,
    required this.storagePath,
    this.isMain = false,
    this.moderationStatus = ModerationStatus.pending,
    this.moderationReason,
    required this.createdAt,
    this.updatedAt,
    this.signedUrl,
    this.isUploading = false,
    this.uploadProgress = 0.0,
  });
  
  factory UserPhoto.fromJson(Map<String, dynamic> json) => _$UserPhotoFromJson(json);
  Map<String, dynamic> toJson() => _$UserPhotoToJson(this);
  
  UserPhoto copyWith({
    String? id,
    String? userId,
    String? storagePath,
    bool? isMain,
    ModerationStatus? moderationStatus,
    String? moderationReason,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? signedUrl,
    bool? isUploading,
    double? uploadProgress,
  }) {
    return UserPhoto(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      storagePath: storagePath ?? this.storagePath,
      isMain: isMain ?? this.isMain,
      moderationStatus: moderationStatus ?? this.moderationStatus,
      moderationReason: moderationReason ?? this.moderationReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      signedUrl: signedUrl ?? this.signedUrl,
      isUploading: isUploading ?? this.isUploading,
      uploadProgress: uploadProgress ?? this.uploadProgress,
    );
  }
  
  /// Photo visible publiquement
  bool get isPubliclyVisible => moderationStatus == ModerationStatus.approved;
  
  /// Photo en attente de modération
  bool get isPending => moderationStatus == ModerationStatus.pending;
  
  /// Photo rejetée
  bool get isRejected => moderationStatus == ModerationStatus.rejected;
  
  /// Peut être définie comme principale
  bool get canBeMain => isPubliclyVisible;
  
  /// URL à afficher (signée ou placeholder)
  String? get displayUrl {
    if (isUploading) return null;
    return signedUrl;
  }
  
  /// Badge couleur selon statut
  Color get statusColor {
    switch (moderationStatus) {
      case ModerationStatus.pending:
        return AppColors.warning;
      case ModerationStatus.approved:
        return AppColors.success;
      case ModerationStatus.rejected:
        return AppColors.error;
    }
  }
  
  /// Texte statut pour UI
  String get statusText {
    switch (moderationStatus) {
      case ModerationStatus.pending:
        return 'En modération';
      case ModerationStatus.approved:
        return 'Approuvée';
      case ModerationStatus.rejected:
        return 'Rejetée';
    }
  }
  
  /// Icône statut
  IconData get statusIcon {
    switch (moderationStatus) {
      case ModerationStatus.pending:
        return Icons.schedule;
      case ModerationStatus.approved:
        return Icons.check_circle;
      case ModerationStatus.rejected:
        return Icons.cancel;
    }
  }
  
  /// Message d'aide pour statut
  String get statusHelpText {
    switch (moderationStatus) {
      case ModerationStatus.pending:
        return 'Votre photo sera revue dans quelques minutes.';
      case ModerationStatus.approved:
        return 'Photo visible sur votre profil.';
      case ModerationStatus.rejected:
        return moderationReason ?? 'Photo non conforme aux règles.';
    }
  }
  
  /// Peut être supprimée (pas la seule photo principale)
  bool canBeDeleted(List<UserPhoto> allPhotos) {
    if (!isMain) return true;
    
    final approvedPhotos = allPhotos.where((p) => p.isPubliclyVisible).toList();
    return approvedPhotos.length > 1;
  }
  
  /// Nom de fichier pour affichage
  String get fileName => storagePath.split('/').last;
  
  /// Taille estimée (si disponible dans metadata)
  String get sizeDisplay => ''; // TODO: Ajouter si metadata taille disponible
}

enum ModerationStatus {
  @JsonValue('pending')
  pending,
  
  @JsonValue('approved')
  approved,
  
  @JsonValue('rejected')
  rejected;
  
  String get displayName {
    switch (this) {
      case ModerationStatus.pending:
        return 'En attente';
      case ModerationStatus.approved:
        return 'Approuvée';
      case ModerationStatus.rejected:
        return 'Rejetée';
    }
  }
}

/// Résultat upload photo
@JsonSerializable()
class PhotoUploadResult {
  final bool success;
  final UserPhoto? photo;
  final String? error;
  final String? storagePath;
  
  const PhotoUploadResult({
    required this.success,
    this.photo,
    this.error,
    this.storagePath,
  });
  
  factory PhotoUploadResult.fromJson(Map<String, dynamic> json) => _$PhotoUploadResultFromJson(json);
  Map<String, dynamic> toJson() => _$PhotoUploadResultToJson(this);
  
  factory PhotoUploadResult.success(UserPhoto photo) {
    return PhotoUploadResult(
      success: true,
      photo: photo,
      storagePath: photo.storagePath,
    );
  }
  
  factory PhotoUploadResult.error(String error) {
    return PhotoUploadResult(
      success: false,
      error: error,
    );
  }
}

/// Configuration galerie photos
class PhotoGalleryConfig {
  static const int maxPhotos = 6;
  static const int maxFileSizeMB = 5;
  static const List<String> allowedExtensions = ['jpg', 'jpeg', 'png', 'webp'];
  static const int signedUrlExpiryMinutes = 60;
  static const int compressionQuality = 85;
  static const int maxImageSize = 1024;
  
  /// Validation fichier
  static String? validateImageFile(String filePath, int fileSizeBytes) {
    // Extension
    final extension = filePath.split('.').last.toLowerCase();
    if (!allowedExtensions.contains(extension)) {
      return 'Format non supporté. Utilisez JPG, PNG ou WebP.';
    }
    
    // Taille
    final sizeMB = fileSizeBytes / (1024 * 1024);
    if (sizeMB > maxFileSizeMB) {
      return 'Photo trop lourde (max ${maxFileSizeMB}MB).';
    }
    
    return null;
  }
  
  /// Peut ajouter plus de photos
  static bool canAddMorePhotos(int currentCount) {
    return currentCount < maxPhotos;
  }
  
  /// Message limite photos
  static String get maxPhotosMessage {
    return 'Maximum $maxPhotos photos autorisées.';
  }
}
