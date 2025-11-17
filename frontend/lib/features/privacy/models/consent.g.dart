// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'consent.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ConsentImpl _$$ConsentImplFromJson(Map<String, dynamic> json) =>
    _$ConsentImpl(
      id: json['id'] as String,
      userId: json['userId'] as String,
      purpose: json['purpose'] as String,
      version: (json['version'] as num).toInt(),
      granted: json['granted'] as bool,
      grantedAt: json['grantedAt'] == null
          ? null
          : DateTime.parse(json['grantedAt'] as String),
      revokedAt: json['revokedAt'] == null
          ? null
          : DateTime.parse(json['revokedAt'] as String),
      ipAddress: json['ipAddress'] as String?,
      userAgent: json['userAgent'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$ConsentImplToJson(_$ConsentImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'purpose': instance.purpose,
      'version': instance.version,
      'granted': instance.granted,
      'grantedAt': instance.grantedAt?.toIso8601String(),
      'revokedAt': instance.revokedAt?.toIso8601String(),
      'ipAddress': instance.ipAddress,
      'userAgent': instance.userAgent,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };

_$PrivacySettingsImpl _$$PrivacySettingsImplFromJson(
        Map<String, dynamic> json) =>
    _$PrivacySettingsImpl(
      isInvisible: json['isInvisible'] as bool,
      hideAge: json['hideAge'] as bool,
      hideLevel: json['hideLevel'] as bool,
      hideStats: json['hideStats'] as bool,
      hideLastActive: json['hideLastActive'] as bool,
      notificationsPush: json['notificationsPush'] as bool,
      notificationsEmail: json['notificationsEmail'] as bool,
      notificationsMarketing: json['notificationsMarketing'] as bool,
    );

Map<String, dynamic> _$$PrivacySettingsImplToJson(
        _$PrivacySettingsImpl instance) =>
    <String, dynamic>{
      'isInvisible': instance.isInvisible,
      'hideAge': instance.hideAge,
      'hideLevel': instance.hideLevel,
      'hideStats': instance.hideStats,
      'hideLastActive': instance.hideLastActive,
      'notificationsPush': instance.notificationsPush,
      'notificationsEmail': instance.notificationsEmail,
      'notificationsMarketing': instance.notificationsMarketing,
    };

_$VerificationRequestImpl _$$VerificationRequestImplFromJson(
        Map<String, dynamic> json) =>
    _$VerificationRequestImpl(
      id: json['id'] as String,
      userId: json['userId'] as String,
      videoStoragePath: json['videoStoragePath'] as String,
      videoDurationSeconds: (json['videoDurationSeconds'] as num?)?.toInt(),
      videoSizeBytes: (json['videoSizeBytes'] as num?)?.toInt(),
      status: json['status'] as String,
      submittedAt: DateTime.parse(json['submittedAt'] as String),
      reviewedAt: json['reviewedAt'] == null
          ? null
          : DateTime.parse(json['reviewedAt'] as String),
      reviewerId: json['reviewerId'] as String?,
      rejectionReason: json['rejectionReason'] as String?,
      verificationScore: (json['verificationScore'] as num?)?.toDouble(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$VerificationRequestImplToJson(
        _$VerificationRequestImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'videoStoragePath': instance.videoStoragePath,
      'videoDurationSeconds': instance.videoDurationSeconds,
      'videoSizeBytes': instance.videoSizeBytes,
      'status': instance.status,
      'submittedAt': instance.submittedAt.toIso8601String(),
      'reviewedAt': instance.reviewedAt?.toIso8601String(),
      'reviewerId': instance.reviewerId,
      'rejectionReason': instance.rejectionReason,
      'verificationScore': instance.verificationScore,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };

_$AIInteractionImpl _$$AIInteractionImplFromJson(Map<String, dynamic> json) =>
    _$AIInteractionImpl(
      id: json['id'] as String,
      userId: json['userId'] as String,
      matchId: json['matchId'] as String?,
      interactionType: json['interactionType'] as String,
      promptUsed: json['promptUsed'] as String?,
      aiResponse: json['aiResponse'] as String?,
      wasUsed: json['wasUsed'] as bool,
      usedAt: json['usedAt'] == null
          ? null
          : DateTime.parse(json['usedAt'] as String),
      userRating: (json['userRating'] as num?)?.toInt(),
      feedbackText: json['feedbackText'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$AIInteractionImplToJson(_$AIInteractionImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'matchId': instance.matchId,
      'interactionType': instance.interactionType,
      'promptUsed': instance.promptUsed,
      'aiResponse': instance.aiResponse,
      'wasUsed': instance.wasUsed,
      'usedAt': instance.usedAt?.toIso8601String(),
      'userRating': instance.userRating,
      'feedbackText': instance.feedbackText,
      'createdAt': instance.createdAt.toIso8601String(),
    };
