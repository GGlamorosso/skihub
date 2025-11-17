// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_photo.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserPhoto _$UserPhotoFromJson(Map<String, dynamic> json) => UserPhoto(
      id: json['id'] as String,
      userId: json['userId'] as String,
      storagePath: json['storagePath'] as String,
      isMain: json['isMain'] as bool? ?? false,
      moderationStatus: $enumDecodeNullable(
              _$ModerationStatusEnumMap, json['moderationStatus']) ??
          ModerationStatus.pending,
      moderationReason: json['moderationReason'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
      signedUrl: json['signedUrl'] as String?,
      isUploading: json['isUploading'] as bool? ?? false,
      uploadProgress: (json['uploadProgress'] as num?)?.toDouble() ?? 0.0,
    );

Map<String, dynamic> _$UserPhotoToJson(UserPhoto instance) => <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'storagePath': instance.storagePath,
      'isMain': instance.isMain,
      'moderationStatus': _$ModerationStatusEnumMap[instance.moderationStatus]!,
      'moderationReason': instance.moderationReason,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
      'signedUrl': instance.signedUrl,
      'isUploading': instance.isUploading,
      'uploadProgress': instance.uploadProgress,
    };

const _$ModerationStatusEnumMap = {
  ModerationStatus.pending: 'pending',
  ModerationStatus.approved: 'approved',
  ModerationStatus.rejected: 'rejected',
};

PhotoUploadResult _$PhotoUploadResultFromJson(Map<String, dynamic> json) =>
    PhotoUploadResult(
      success: json['success'] as bool,
      photo: json['photo'] == null
          ? null
          : UserPhoto.fromJson(json['photo'] as Map<String, dynamic>),
      error: json['error'] as String?,
      storagePath: json['storagePath'] as String?,
    );

Map<String, dynamic> _$PhotoUploadResultToJson(PhotoUploadResult instance) =>
    <String, dynamic>{
      'success': instance.success,
      'photo': instance.photo,
      'error': instance.error,
      'storagePath': instance.storagePath,
    };
