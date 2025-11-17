import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/material.dart';

part 'moderation.freezed.dart';
part 'moderation.g.dart';

@freezed
class ReportReason with _$ReportReason {
  const factory ReportReason.inappropriateContent() = _InappropriateContent;
  const factory ReportReason.harassment() = _Harassment;
  const factory ReportReason.spam() = _Spam;
  const factory ReportReason.fakeProfile() = _FakeProfile;
  const factory ReportReason.other(String description) = _Other;
  
  const ReportReason._();
  
  String get displayName {
    return when(
      inappropriateContent: () => 'Contenu inapproprié',
      harassment: () => 'Harcèlement',
      spam: () => 'Spam ou arnaque',
      fakeProfile: () => 'Faux profil',
      other: (description) => 'Autre: $description',
    );
  }
  
  IconData get icon {
    return when(
      inappropriateContent: () => Icons.explicit,
      harassment: () => Icons.person_off,
      spam: () => Icons.money_off,
      fakeProfile: () => Icons.face_retouching_off,
      other: (_) => Icons.flag,
    );
  }
}

@freezed
class UserReport with _$UserReport {
  const factory UserReport({
    required String id,
    required String reporterId,
    required String reportedUserId,
    @JsonKey(fromJson: _reportReasonFromJson, toJson: _reportReasonToJson)
    required ReportReason reason,
    String? description,
    List<String>? messageIds,
    required String status,
    required DateTime createdAt,
    DateTime? reviewedAt,
    String? reviewerId,
    String? adminNotes,
  }) = _UserReport;

  factory UserReport.fromJson(Map<String, dynamic> json) =>
      _$UserReportFromJson(json);

  const UserReport._();

  bool get isPending => status == 'pending';
  bool get isResolved => status == 'resolved';
  bool get isDismissed => status == 'dismissed';

  String get statusDisplay {
    switch (status) {
      case 'pending':
        return 'En cours d\'examen';
      case 'resolved':
        return 'Résolu';
      case 'dismissed':
        return 'Rejeté';
      default:
        return status;
    }
  }

  Color get statusColor {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'resolved':
        return Colors.green;
      case 'dismissed':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}

@freezed
class BlockedUser with _$BlockedUser {
  const factory BlockedUser({
    required String id,
    required String userId,
    required String blockedUserId,
    required String blockedUsername,
    String? reason,
    required DateTime createdAt,
    // User info (from join)
    String? profilePhotoUrl,
    String? userLevel,
  }) = _BlockedUser;

  factory BlockedUser.fromJson(Map<String, dynamic> json) =>
      _$BlockedUserFromJson(json);
}

@freezed
class ModerationAction with _$ModerationAction {
  const factory ModerationAction({
    required String id,
    required String userId,
    required String action, // 'message_blocked', 'photo_rejected', etc.
    required String reason,
    String? description,
    Map<String, dynamic>? metadata,
    required String status,
    required DateTime createdAt,
    DateTime? resolvedAt,
  }) = _ModerationAction;

  factory ModerationAction.fromJson(Map<String, dynamic> json) =>
      _$ModerationActionFromJson(json);

  const ModerationAction._();

  String get actionDisplay {
    switch (action) {
      case 'message_blocked':
        return 'Message bloqué';
      case 'photo_rejected':
        return 'Photo rejetée';
      case 'profile_suspended':
        return 'Profil suspendu';
      case 'verification_rejected':
        return 'Vérification rejetée';
      default:
        return action;
    }
  }

  IconData get actionIcon {
    switch (action) {
      case 'message_blocked':
        return Icons.block;
      case 'photo_rejected':
        return Icons.photo_camera;
      case 'profile_suspended':
        return Icons.person_off;
      case 'verification_rejected':
        return Icons.verified_user;
      default:
        return Icons.gavel;
    }
  }

  Color get actionColor {
    switch (action) {
      case 'message_blocked':
        return Colors.red;
      case 'photo_rejected':
        return Colors.orange;
      case 'profile_suspended':
        return Colors.purple;
      case 'verification_rejected':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  bool get canAppeal => status == 'active' && action != 'profile_suspended';
}

@freezed
class SafetyNotification with _$SafetyNotification {
  const factory SafetyNotification({
    required String id,
    required String userId,
    required String type,
    required String title,
    required String message,
    Map<String, dynamic>? data,
    required bool isRead,
    required DateTime createdAt,
    DateTime? readAt,
  }) = _SafetyNotification;

  factory SafetyNotification.fromJson(Map<String, dynamic> json) =>
      _$SafetyNotificationFromJson(json);

  const SafetyNotification._();

  IconData get typeIcon {
    switch (type) {
      case 'message_blocked':
        return Icons.block;
      case 'photo_rejected':
        return Icons.photo_camera;
      case 'verification_approved':
        return Icons.check_circle;
      case 'verification_rejected':
        return Icons.cancel;
      case 'safety_alert':
        return Icons.warning;
      case 'community_update':
        return Icons.info;
      default:
        return Icons.notifications;
    }
  }

  Color get typeColor {
    switch (type) {
      case 'message_blocked':
        return Colors.red;
      case 'photo_rejected':
        return Colors.orange;
      case 'verification_approved':
        return Colors.green;
      case 'verification_rejected':
        return Colors.red;
      case 'safety_alert':
        return Colors.red;
      case 'community_update':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  bool get isUrgent => ['safety_alert', 'message_blocked'].contains(type);
}

// Helper functions for ReportReason serialization
ReportReason _reportReasonFromJson(Map<String, dynamic> json) {
  final type = json['type'] as String;
  switch (type) {
    case 'inappropriate_content':
      return const ReportReason.inappropriateContent();
    case 'harassment':
      return const ReportReason.harassment();
    case 'spam':
      return const ReportReason.spam();
    case 'fake_profile':
      return const ReportReason.fakeProfile();
    case 'other':
      return ReportReason.other(json['description'] as String? ?? '');
    default:
      return const ReportReason.other('Unknown');
  }
}

Map<String, dynamic> _reportReasonToJson(ReportReason reason) {
  return reason.when(
    inappropriateContent: () => {'type': 'inappropriate_content'},
    harassment: () => {'type': 'harassment'},
    spam: () => {'type': 'spam'},
    fakeProfile: () => {'type': 'fake_profile'},
    other: (description) => {'type': 'other', 'description': description},
  );
}
