// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SubscriptionImpl _$$SubscriptionImplFromJson(Map<String, dynamic> json) =>
    _$SubscriptionImpl(
      id: json['id'] as String,
      userId: json['userId'] as String,
      stripeSubscriptionId: json['stripeSubscriptionId'] as String,
      stripeCustomerId: json['stripeCustomerId'] as String,
      stripePriceId: json['stripePriceId'] as String,
      status: json['status'] as String,
      currentPeriodStart: DateTime.parse(json['currentPeriodStart'] as String),
      currentPeriodEnd: DateTime.parse(json['currentPeriodEnd'] as String),
      cancelAtPeriodEnd: json['cancelAtPeriodEnd'] as bool,
      canceledAt: json['canceledAt'] == null
          ? null
          : DateTime.parse(json['canceledAt'] as String),
      amountCents: (json['amountCents'] as num).toInt(),
      currency: json['currency'] as String,
      interval: json['interval'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$SubscriptionImplToJson(_$SubscriptionImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'stripeSubscriptionId': instance.stripeSubscriptionId,
      'stripeCustomerId': instance.stripeCustomerId,
      'stripePriceId': instance.stripePriceId,
      'status': instance.status,
      'currentPeriodStart': instance.currentPeriodStart.toIso8601String(),
      'currentPeriodEnd': instance.currentPeriodEnd.toIso8601String(),
      'cancelAtPeriodEnd': instance.cancelAtPeriodEnd,
      'canceledAt': instance.canceledAt?.toIso8601String(),
      'amountCents': instance.amountCents,
      'currency': instance.currency,
      'interval': instance.interval,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };

_$QuotaInfoImpl _$$QuotaInfoImplFromJson(Map<String, dynamic> json) =>
    _$QuotaInfoImpl(
      swipeRemaining: (json['swipeRemaining'] as num).toInt(),
      messageRemaining: (json['messageRemaining'] as num).toInt(),
      limitReached: json['limitReached'] as bool,
      limitType: json['limitType'] as String?,
      resetsAt: DateTime.parse(json['resetsAt'] as String),
      isPremium: json['isPremium'] as bool,
    );

Map<String, dynamic> _$$QuotaInfoImplToJson(_$QuotaInfoImpl instance) =>
    <String, dynamic>{
      'swipeRemaining': instance.swipeRemaining,
      'messageRemaining': instance.messageRemaining,
      'limitReached': instance.limitReached,
      'limitType': instance.limitType,
      'resetsAt': instance.resetsAt.toIso8601String(),
      'isPremium': instance.isPremium,
    };

_$BoostImpl _$$BoostImplFromJson(Map<String, dynamic> json) => _$BoostImpl(
      id: json['id'] as String,
      userId: json['userId'] as String,
      stationId: json['stationId'] as String,
      startsAt: DateTime.parse(json['startsAt'] as String),
      endsAt: DateTime.parse(json['endsAt'] as String),
      boostMultiplier: (json['boostMultiplier'] as num).toDouble(),
      amountPaidCents: (json['amountPaidCents'] as num).toInt(),
      currency: json['currency'] as String,
      stripePaymentIntentId: json['stripePaymentIntentId'] as String?,
      isActive: json['isActive'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      stationName: json['stationName'] as String?,
      stationCountryCode: json['stationCountryCode'] as String?,
    );

Map<String, dynamic> _$$BoostImplToJson(_$BoostImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'stationId': instance.stationId,
      'startsAt': instance.startsAt.toIso8601String(),
      'endsAt': instance.endsAt.toIso8601String(),
      'boostMultiplier': instance.boostMultiplier,
      'amountPaidCents': instance.amountPaidCents,
      'currency': instance.currency,
      'stripePaymentIntentId': instance.stripePaymentIntentId,
      'isActive': instance.isActive,
      'createdAt': instance.createdAt.toIso8601String(),
      'stationName': instance.stationName,
      'stationCountryCode': instance.stationCountryCode,
    };

_$PremiumPlanImpl _$$PremiumPlanImplFromJson(Map<String, dynamic> json) =>
    _$PremiumPlanImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      priceMonthly: (json['priceMonthly'] as num).toInt(),
      priceYearly: (json['priceYearly'] as num).toInt(),
      currency: json['currency'] as String,
      features:
          (json['features'] as List<dynamic>).map((e) => e as String).toList(),
      isPopular: json['isPopular'] as bool,
      stripePriceIdMonthly: json['stripePriceIdMonthly'] as String?,
      stripePriceIdYearly: json['stripePriceIdYearly'] as String?,
    );

Map<String, dynamic> _$$PremiumPlanImplToJson(_$PremiumPlanImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'priceMonthly': instance.priceMonthly,
      'priceYearly': instance.priceYearly,
      'currency': instance.currency,
      'features': instance.features,
      'isPopular': instance.isPopular,
      'stripePriceIdMonthly': instance.stripePriceIdMonthly,
      'stripePriceIdYearly': instance.stripePriceIdYearly,
    };
