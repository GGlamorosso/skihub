import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/material.dart';

part 'beta_feedback.freezed.dart';
part 'beta_feedback.g.dart';

@freezed
class BetaFeedback with _$BetaFeedback {
  const factory BetaFeedback({
    required String id,
    required String userId,
    String? subject,
    required String description,
    int? rating,
    required FeedbackCategory category,
    String? appVersion,
    Map<String, dynamic>? deviceInfo,
    String? screenshotUrl,
    required FeedbackStatus status,
    required FeedbackPriority priority,
    String? assignedTo,
    DateTime? processedAt,
    String? response,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _BetaFeedback;

  factory BetaFeedback.fromJson(Map<String, dynamic> json) =>
      _$BetaFeedbackFromJson(json);

  const BetaFeedback._();

  String get statusDisplay {
    switch (status) {
      case FeedbackStatus.newFeedback:
        return 'Nouveau';
      case FeedbackStatus.inProgress:
        return 'En cours';
      case FeedbackStatus.resolved:
        return 'Résolu';
      case FeedbackStatus.closed:
        return 'Fermé';
      case FeedbackStatus.duplicate:
        return 'Doublon';
    }
  }

  Color get statusColor {
    switch (status) {
      case FeedbackStatus.newFeedback:
        return Colors.blue;
      case FeedbackStatus.inProgress:
        return Colors.orange;
      case FeedbackStatus.resolved:
        return Colors.green;
      case FeedbackStatus.closed:
        return Colors.grey;
      case FeedbackStatus.duplicate:
        return Colors.purple;
    }
  }

  String get priorityDisplay {
    switch (priority) {
      case FeedbackPriority.low:
        return 'Basse';
      case FeedbackPriority.medium:
        return 'Moyenne';
      case FeedbackPriority.high:
        return 'Haute';
      case FeedbackPriority.critical:
        return 'Critique';
    }
  }

  Color get priorityColor {
    switch (priority) {
      case FeedbackPriority.low:
        return Colors.green;
      case FeedbackPriority.medium:
        return Colors.orange;
      case FeedbackPriority.high:
        return Colors.red;
      case FeedbackPriority.critical:
        return Colors.purple;
    }
  }

  bool get hasScreenshot => screenshotUrl != null;
  bool get hasRating => rating != null;
  bool get isResolved => status == FeedbackStatus.resolved || status == FeedbackStatus.closed;
  bool get canRespond => status == FeedbackStatus.newFeedback || status == FeedbackStatus.inProgress;

  String get ratingDisplay {
    if (rating == null) return 'Non noté';
    return '$rating/5 étoiles';
  }
}

enum FeedbackCategory {
  general('general', 'Général', Icons.feedback),
  bug('bug', 'Bug', Icons.bug_report),
  featureRequest('feature_request', 'Demande de fonctionnalité', Icons.lightbulb),
  uiUx('ui_ux', 'Interface utilisateur', Icons.design_services),
  performance('performance', 'Performance', Icons.speed),
  matching('matching', 'Matching', Icons.favorite),
  chat('chat', 'Chat', Icons.message),
  premium('premium', 'Premium', Icons.star),
  tracking('tracking', 'Tracking', Icons.timeline),
  privacy('privacy', 'Confidentialité', Icons.privacy_tip);

  const FeedbackCategory(this.value, this.displayName, this.icon);

  final String value;
  final String displayName;
  final IconData icon;

  static FeedbackCategory fromString(String value) {
    return FeedbackCategory.values.firstWhere(
      (category) => category.value == value,
      orElse: () => FeedbackCategory.general,
    );
  }
}

enum FeedbackStatus {
  newFeedback('new'),
  inProgress('in_progress'),
  resolved('resolved'),
  closed('closed'),
  duplicate('duplicate');

  const FeedbackStatus(this.value);

  final String value;

  static FeedbackStatus fromString(String value) {
    return FeedbackStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => FeedbackStatus.newFeedback,
    );
  }
}

enum FeedbackPriority {
  low('low'),
  medium('medium'),
  high('high'),
  critical('critical');

  const FeedbackPriority(this.value);

  final String value;

  static FeedbackPriority fromString(String value) {
    return FeedbackPriority.values.firstWhere(
      (priority) => priority.value == value,
      orElse: () => FeedbackPriority.medium,
    );
  }
}

@freezed
class QuickFeedback with _$QuickFeedback {
  const factory QuickFeedback({
    required String id,
    required String userId,
    required bool positive,
    required String context,
    String? sessionId,
    Map<String, dynamic>? deviceInfo,
    required DateTime createdAt,
  }) = _QuickFeedback;

  factory QuickFeedback.fromJson(Map<String, dynamic> json) =>
      _$QuickFeedbackFromJson(json);
}

@freezed
class FeedbackMetrics with _$FeedbackMetrics {
  const factory FeedbackMetrics({
    required int totalFeedback,
    required int newFeedback,
    required int resolvedFeedback,
    required double averageRating,
    required Map<String, int> categoryBreakdown,
    required Map<String, int> statusBreakdown,
    required DateTime lastUpdated,
  }) = _FeedbackMetrics;

  factory FeedbackMetrics.fromJson(Map<String, dynamic> json) =>
      _$FeedbackMetricsFromJson(json);

  const FeedbackMetrics._();

  double get resolutionRate {
    if (totalFeedback == 0) return 0.0;
    return resolvedFeedback / totalFeedback;
  }

  String get averageRatingDisplay => averageRating.toStringAsFixed(1);
  
  FeedbackCategory get mostCommonCategory {
    if (categoryBreakdown.isEmpty) return FeedbackCategory.general;
    
    final maxEntry = categoryBreakdown.entries.reduce(
      (a, b) => a.value > b.value ? a : b,
    );
    
    return FeedbackCategory.fromString(maxEntry.key);
  }
}
