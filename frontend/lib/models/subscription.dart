import 'package:freezed_annotation/freezed_annotation.dart';

part 'subscription.freezed.dart';
part 'subscription.g.dart';

@freezed
class Subscription with _$Subscription {
  const factory Subscription({
    required String id,
    required String userId,
    required String stripeSubscriptionId,
    required String stripeCustomerId,
    required String stripePriceId,
    required SubscriptionStatus status,
    required DateTime currentPeriodStart,
    required DateTime currentPeriodEnd,
    required bool cancelAtPeriodEnd,
    DateTime? canceledAt,
    required int amountCents,
    required String currency,
    required String interval, // 'month' or 'year'
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Subscription;

  factory Subscription.fromJson(Map<String, dynamic> json) => _$SubscriptionFromJson(json);
}

@freezed
class QuotaInfo with _$QuotaInfo {
  const factory QuotaInfo({
    required int swipeRemaining,
    required int messageRemaining,
    required bool limitReached,
    required QuotaType limitType,
    required int dailySwipeLimit,
    required int dailyMessageLimit,
    required DateTime resetsAt,
  }) = _QuotaInfo;

  factory QuotaInfo.fromJson(Map<String, dynamic> json) => _$QuotaInfoFromJson(json);
}

@freezed
class Boost with _$Boost {
  const factory Boost({
    required String id,
    required String userId,
    required String stationId,
    required DateTime startsAt,
    required DateTime endsAt,
    required double boostMultiplier,
    required int amountPaidCents,
    required String currency,
    String? stripePaymentIntentId,
    required bool isActive,
    required DateTime createdAt,
    // Computed fields
    String? stationName,
    Duration? remainingDuration,
  }) = _Boost;

  factory Boost.fromJson(Map<String, dynamic> json) => _$BoostFromJson(json);
}

@freezed
class PremiumPlan with _$PremiumPlan {
  const factory PremiumPlan({
    required String id,
    required String name,
    required String description,
    required int amountCents,
    required String currency,
    required String interval,
    required List<String> features,
    required bool isPopular,
    String? stripePriceId,
    int? discountPercent,
  }) = _PremiumPlan;

  factory PremiumPlan.fromJson(Map<String, dynamic> json) => _$PremiumPlanFromJson(json);
}

enum SubscriptionStatus {
  @JsonValue('active')
  active,
  @JsonValue('canceled')
  canceled,
  @JsonValue('incomplete')
  incomplete,
  @JsonValue('incomplete_expired')
  incompleteExpired,
  @JsonValue('past_due')
  pastDue,
  @JsonValue('trialing')
  trialing,
  @JsonValue('unpaid')
  unpaid,
}

enum QuotaType {
  @JsonValue('swipe')
  swipe,
  @JsonValue('message')
  message,
  @JsonValue('none')
  none,
}

extension SubscriptionStatusX on SubscriptionStatus {
  bool get isActive => this == SubscriptionStatus.active || this == SubscriptionStatus.trialing;
  
  String get displayName {
    switch (this) {
      case SubscriptionStatus.active:
        return 'Active';
      case SubscriptionStatus.canceled:
        return 'Cancelled';
      case SubscriptionStatus.incomplete:
        return 'Incomplete';
      case SubscriptionStatus.incompleteExpired:
        return 'Expired';
      case SubscriptionStatus.pastDue:
        return 'Payment Due';
      case SubscriptionStatus.trialing:
        return 'Trial';
      case SubscriptionStatus.unpaid:
        return 'Unpaid';
    }
  }
}

extension QuotaInfoX on QuotaInfo {
  bool get hasSwipes => swipeRemaining > 0;
  bool get hasMessages => messageRemaining > 0;
  bool get isSwipeLimited => limitReached && limitType == QuotaType.swipe;
  bool get isMessageLimited => limitReached && limitType == QuotaType.message;
  
  double get swipeProgress => swipeRemaining / dailySwipeLimit;
  double get messageProgress => messageRemaining / dailyMessageLimit;
  
  /// Message quota pour UI
  String get quotaMessage {
    if (limitReached) {
      if (limitType == QuotaType.swipe) {
        return 'Limite de swipes atteinte. Plus que $swipeRemaining swipes.';
      } else if (limitType == QuotaType.message) {
        return 'Limite de messages atteinte. Plus que $messageRemaining messages.';
      }
      return 'Limite quotidienne atteinte.';
    }
    
    if (swipeRemaining <= 5) {
      return 'Plus que $swipeRemaining swipes aujourd\'hui.';
    }
    
    return '$swipeRemaining swipes restants.';
  }
  
  /// Temps avant reset
  String? get resetTimeDisplay {
    final now = DateTime.now();
    final diff = resetsAt.difference(now);
    
    if (diff.inHours > 0) {
      return 'Reset dans ${diff.inHours}h${diff.inMinutes % 60}min';
    } else if (diff.inMinutes > 0) {
      return 'Reset dans ${diff.inMinutes}min';
    }
    
    return 'Reset imminent';
  }
}

extension BoostX on Boost {
  bool get isCurrentlyActive {
    final now = DateTime.now();
    return isActive && now.isAfter(startsAt) && now.isBefore(endsAt);
  }
  
  Duration get timeRemaining {
    final now = DateTime.now();
    if (!isCurrentlyActive) return Duration.zero;
    return endsAt.difference(now);
  }
  
  String get timeRemainingText {
    final remaining = timeRemaining;
    if (remaining.inDays > 0) {
      return '${remaining.inDays}j ${remaining.inHours % 24}h';
    } else if (remaining.inHours > 0) {
      return '${remaining.inHours}h ${remaining.inMinutes % 60}min';
    } else {
      return '${remaining.inMinutes}min';
    }
  }
}

extension PremiumPlanX on PremiumPlan {
  double get monthlyPrice => amountCents / 100.0;
  
  String get priceText {
    final price = monthlyPrice;
    switch (interval) {
      case 'month':
        return '${price.toStringAsFixed(2)} €/mois';
      case 'year':
        final monthlyEquivalent = price / 12;
        return '${price.toStringAsFixed(2)} €/an (${monthlyEquivalent.toStringAsFixed(2)} €/mois)';
      default:
        return '${price.toStringAsFixed(2)} €';
    }
  }
  
  String get savingsText {
    if (discountPercent != null && discountPercent! > 0) {
      return 'Économisez $discountPercent%';
    }
    return '';
  }
}
