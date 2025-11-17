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
    required String status,
    required DateTime currentPeriodStart,
    required DateTime currentPeriodEnd,
    required bool cancelAtPeriodEnd,
    DateTime? canceledAt,
    required int amountCents,
    required String currency,
    required String interval,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Subscription;

  factory Subscription.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionFromJson(json);

  const Subscription._();

  bool get isActive => status == 'active' && currentPeriodEnd.isAfter(DateTime.now());
  bool get isTrialing => status == 'trialing';
  bool get isCanceled => status == 'canceled' || cancelAtPeriodEnd;
  bool get isPastDue => status == 'past_due';
  bool get hasValidAccess => isActive || isTrialing;
  
  String get displayStatus {
    switch (status) {
      case 'active':
        return 'Actif';
      case 'trialing':
        return 'Période d\'essai';
      case 'canceled':
        return 'Annulé';
      case 'past_due':
        return 'Paiement en retard';
      case 'incomplete':
        return 'Incomplet';
      default:
        return status;
    }
  }

  String get displayInterval {
    switch (interval) {
      case 'month':
        return 'Mensuel';
      case 'year':
        return 'Annuel';
      default:
        return interval;
    }
  }

  double get displayAmount => amountCents / 100.0;

  int get daysUntilRenewal => currentPeriodEnd.difference(DateTime.now()).inDays;
  
  bool get renewsWithin7Days => daysUntilRenewal <= 7 && daysUntilRenewal >= 0;
}

@freezed
class QuotaInfo with _$QuotaInfo {
  const factory QuotaInfo({
    required int swipeRemaining,
    required int messageRemaining,
    required bool limitReached,
    String? limitType,
    required DateTime resetsAt,
    required bool isPremium,
  }) = _QuotaInfo;

  factory QuotaInfo.fromJson(Map<String, dynamic> json) =>
      _$QuotaInfoFromJson(json);

  const QuotaInfo._();

  bool get hasUnlimitedSwipes => isPremium || swipeRemaining == -1;
  bool get hasUnlimitedMessages => isPremium || messageRemaining == -1;
  bool get isSwipeLimited => limitReached && limitType == 'swipe';
  bool get isMessageLimited => limitReached && limitType == 'message';
  
  String get limitMessage {
    if (!limitReached) return '';
    
    switch (limitType) {
      case 'swipe':
        return 'Limite de swipes quotidiens atteinte';
      case 'message':
        return 'Limite de messages quotidiens atteinte';
      default:
        return 'Limite quotidienne atteinte';
    }
  }

  String get resetTimeDisplay {
    final now = DateTime.now();
    final duration = resetsAt.difference(now);
    
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}min';
    } else {
      return '${duration.inMinutes}min';
    }
  }
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
    // Station info (from join)
    String? stationName,
    String? stationCountryCode,
  }) = _Boost;

  factory Boost.fromJson(Map<String, dynamic> json) =>
      _$BoostFromJson(json);

  const Boost._();

  bool get isCurrentlyActive {
    final now = DateTime.now();
    return isActive && now.isAfter(startsAt) && now.isBefore(endsAt);
  }

  bool get isUpcoming => DateTime.now().isBefore(startsAt);
  bool get isExpired => DateTime.now().isAfter(endsAt);

  Duration get timeRemaining {
    final now = DateTime.now();
    if (now.isAfter(endsAt)) return Duration.zero;
    return endsAt.difference(now);
  }

  Duration get timeUntilStart {
    final now = DateTime.now();
    if (now.isAfter(startsAt)) return Duration.zero;
    return startsAt.difference(now);
  }

  String get statusDisplay {
    if (isUpcoming) return 'À venir';
    if (isCurrentlyActive) return 'Actif';
    if (isExpired) return 'Expiré';
    return 'Inactif';
  }

  String get timeRemainingDisplay {
    final remaining = timeRemaining;
    if (remaining == Duration.zero) return 'Expiré';
    
    if (remaining.inDays > 0) {
      return '${remaining.inDays}j ${remaining.inHours % 24}h';
    } else if (remaining.inHours > 0) {
      return '${remaining.inHours}h ${remaining.inMinutes % 60}min';
    } else {
      return '${remaining.inMinutes}min';
    }
  }

  double get displayAmount => amountPaidCents / 100.0;

  String get multiplierDisplay => '${boostMultiplier}x';
}

@freezed
class PremiumPlan with _$PremiumPlan {
  const factory PremiumPlan({
    required String id,
    required String name,
    required String description,
    required int priceMonthly,
    required int priceYearly,
    required String currency,
    required List<String> features,
    required bool isPopular,
    String? stripePriceIdMonthly,
    String? stripePriceIdYearly,
  }) = _PremiumPlan;

  factory PremiumPlan.fromJson(Map<String, dynamic> json) =>
      _$PremiumPlanFromJson(json);

  const PremiumPlan._();

  double get displayPriceMonthly => priceMonthly / 100.0;
  double get displayPriceYearly => priceYearly / 100.0;
  double get yearlySavings => (priceMonthly * 12 - priceYearly) / 100.0;
  int get yearlySavingsPercent => ((yearlySavings / (priceMonthly * 12 / 100.0)) * 100).round();
}

enum SubscriptionStatus {
  active,
  canceled,
  incomplete,
  incompleteExpired,
  pastDue,
  trialing,
  unpaid;

  bool get hasAccess => this == SubscriptionStatus.active || this == SubscriptionStatus.trialing;
}

enum BoostType {
  hourly('1h', 1, 299),
  daily('24h', 24, 999), 
  weekly('7j', 168, 1999);

  const BoostType(this.displayName, this.durationHours, this.priceCents);

  final String displayName;
  final int durationHours;
  final int priceCents;

  double get displayPrice => priceCents / 100.0;
  String get description {
    switch (this) {
      case hourly:
        return 'Boost 1 heure pour maximum de visibilité';
      case daily:
        return 'Boost 24 heures pour une journée entière';
      case weekly:
        return 'Boost 7 jours pour toute la semaine';
    }
  }

  double get multiplier {
    switch (this) {
      case hourly:
        return 2.0;
      case daily:
        return 3.0;
      case weekly:
        return 5.0;
    }
  }
}
