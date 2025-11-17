// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'beta_feedback.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$BetaFeedbackImpl _$$BetaFeedbackImplFromJson(Map<String, dynamic> json) =>
    _$BetaFeedbackImpl(
      id: json['id'] as String,
      userId: json['userId'] as String,
      subject: json['subject'] as String?,
      description: json['description'] as String,
      rating: (json['rating'] as num?)?.toInt(),
      category: $enumDecode(_$FeedbackCategoryEnumMap, json['category']),
      appVersion: json['appVersion'] as String?,
      deviceInfo: json['deviceInfo'] as Map<String, dynamic>?,
      screenshotUrl: json['screenshotUrl'] as String?,
      status: $enumDecode(_$FeedbackStatusEnumMap, json['status']),
      priority: $enumDecode(_$FeedbackPriorityEnumMap, json['priority']),
      assignedTo: json['assignedTo'] as String?,
      processedAt: json['processedAt'] == null
          ? null
          : DateTime.parse(json['processedAt'] as String),
      response: json['response'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$BetaFeedbackImplToJson(_$BetaFeedbackImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'subject': instance.subject,
      'description': instance.description,
      'rating': instance.rating,
      'category': _$FeedbackCategoryEnumMap[instance.category]!,
      'appVersion': instance.appVersion,
      'deviceInfo': instance.deviceInfo,
      'screenshotUrl': instance.screenshotUrl,
      'status': _$FeedbackStatusEnumMap[instance.status]!,
      'priority': _$FeedbackPriorityEnumMap[instance.priority]!,
      'assignedTo': instance.assignedTo,
      'processedAt': instance.processedAt?.toIso8601String(),
      'response': instance.response,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };

const _$FeedbackCategoryEnumMap = {
  FeedbackCategory.general: 'general',
  FeedbackCategory.bug: 'bug',
  FeedbackCategory.featureRequest: 'featureRequest',
  FeedbackCategory.uiUx: 'uiUx',
  FeedbackCategory.performance: 'performance',
  FeedbackCategory.matching: 'matching',
  FeedbackCategory.chat: 'chat',
  FeedbackCategory.premium: 'premium',
  FeedbackCategory.tracking: 'tracking',
  FeedbackCategory.privacy: 'privacy',
};

const _$FeedbackStatusEnumMap = {
  FeedbackStatus.newFeedback: 'newFeedback',
  FeedbackStatus.inProgress: 'inProgress',
  FeedbackStatus.resolved: 'resolved',
  FeedbackStatus.closed: 'closed',
  FeedbackStatus.duplicate: 'duplicate',
};

const _$FeedbackPriorityEnumMap = {
  FeedbackPriority.low: 'low',
  FeedbackPriority.medium: 'medium',
  FeedbackPriority.high: 'high',
  FeedbackPriority.critical: 'critical',
};

_$QuickFeedbackImpl _$$QuickFeedbackImplFromJson(Map<String, dynamic> json) =>
    _$QuickFeedbackImpl(
      id: json['id'] as String,
      userId: json['userId'] as String,
      positive: json['positive'] as bool,
      context: json['context'] as String,
      sessionId: json['sessionId'] as String?,
      deviceInfo: json['deviceInfo'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$QuickFeedbackImplToJson(_$QuickFeedbackImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'positive': instance.positive,
      'context': instance.context,
      'sessionId': instance.sessionId,
      'deviceInfo': instance.deviceInfo,
      'createdAt': instance.createdAt.toIso8601String(),
    };

_$FeedbackMetricsImpl _$$FeedbackMetricsImplFromJson(
        Map<String, dynamic> json) =>
    _$FeedbackMetricsImpl(
      totalFeedback: (json['totalFeedback'] as num).toInt(),
      newFeedback: (json['newFeedback'] as num).toInt(),
      resolvedFeedback: (json['resolvedFeedback'] as num).toInt(),
      averageRating: (json['averageRating'] as num).toDouble(),
      categoryBreakdown:
          Map<String, int>.from(json['categoryBreakdown'] as Map),
      statusBreakdown: Map<String, int>.from(json['statusBreakdown'] as Map),
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );

Map<String, dynamic> _$$FeedbackMetricsImplToJson(
        _$FeedbackMetricsImpl instance) =>
    <String, dynamic>{
      'totalFeedback': instance.totalFeedback,
      'newFeedback': instance.newFeedback,
      'resolvedFeedback': instance.resolvedFeedback,
      'averageRating': instance.averageRating,
      'categoryBreakdown': instance.categoryBreakdown,
      'statusBreakdown': instance.statusBreakdown,
      'lastUpdated': instance.lastUpdated.toIso8601String(),
    };
