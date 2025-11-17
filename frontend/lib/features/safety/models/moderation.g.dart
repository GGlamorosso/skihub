// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'moderation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserReportImpl _$$UserReportImplFromJson(Map<String, dynamic> json) =>
    _$UserReportImpl(
      id: json['id'] as String,
      reporterId: json['reporterId'] as String,
      reportedUserId: json['reportedUserId'] as String,
      reason: _reportReasonFromJson(json['reason'] as Map<String, dynamic>),
      description: json['description'] as String?,
      messageIds: (json['messageIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      reviewedAt: json['reviewedAt'] == null
          ? null
          : DateTime.parse(json['reviewedAt'] as String),
      reviewerId: json['reviewerId'] as String?,
      adminNotes: json['adminNotes'] as String?,
    );

Map<String, dynamic> _$$UserReportImplToJson(_$UserReportImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'reporterId': instance.reporterId,
      'reportedUserId': instance.reportedUserId,
      'reason': _reportReasonToJson(instance.reason),
      'description': instance.description,
      'messageIds': instance.messageIds,
      'status': instance.status,
      'createdAt': instance.createdAt.toIso8601String(),
      'reviewedAt': instance.reviewedAt?.toIso8601String(),
      'reviewerId': instance.reviewerId,
      'adminNotes': instance.adminNotes,
    };

_$BlockedUserImpl _$$BlockedUserImplFromJson(Map<String, dynamic> json) =>
    _$BlockedUserImpl(
      id: json['id'] as String,
      userId: json['userId'] as String,
      blockedUserId: json['blockedUserId'] as String,
      blockedUsername: json['blockedUsername'] as String,
      reason: json['reason'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      profilePhotoUrl: json['profilePhotoUrl'] as String?,
      userLevel: json['userLevel'] as String?,
    );

Map<String, dynamic> _$$BlockedUserImplToJson(_$BlockedUserImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'blockedUserId': instance.blockedUserId,
      'blockedUsername': instance.blockedUsername,
      'reason': instance.reason,
      'createdAt': instance.createdAt.toIso8601String(),
      'profilePhotoUrl': instance.profilePhotoUrl,
      'userLevel': instance.userLevel,
    };

_$ModerationActionImpl _$$ModerationActionImplFromJson(
        Map<String, dynamic> json) =>
    _$ModerationActionImpl(
      id: json['id'] as String,
      userId: json['userId'] as String,
      action: json['action'] as String,
      reason: json['reason'] as String,
      description: json['description'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      resolvedAt: json['resolvedAt'] == null
          ? null
          : DateTime.parse(json['resolvedAt'] as String),
    );

Map<String, dynamic> _$$ModerationActionImplToJson(
        _$ModerationActionImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'action': instance.action,
      'reason': instance.reason,
      'description': instance.description,
      'metadata': instance.metadata,
      'status': instance.status,
      'createdAt': instance.createdAt.toIso8601String(),
      'resolvedAt': instance.resolvedAt?.toIso8601String(),
    };

_$SafetyNotificationImpl _$$SafetyNotificationImplFromJson(
        Map<String, dynamic> json) =>
    _$SafetyNotificationImpl(
      id: json['id'] as String,
      userId: json['userId'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      data: json['data'] as Map<String, dynamic>?,
      isRead: json['isRead'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      readAt: json['readAt'] == null
          ? null
          : DateTime.parse(json['readAt'] as String),
    );

Map<String, dynamic> _$$SafetyNotificationImplToJson(
        _$SafetyNotificationImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'type': instance.type,
      'title': instance.title,
      'message': instance.message,
      'data': instance.data,
      'isRead': instance.isRead,
      'createdAt': instance.createdAt.toIso8601String(),
      'readAt': instance.readAt?.toIso8601String(),
    };
