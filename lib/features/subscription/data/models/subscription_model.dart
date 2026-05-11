import 'package:hamro_pasal/core/constants/app_constants.dart';

class Subscription {
  final String id;
  final String businessId;
  final String? planId;
  final String status;
  final DateTime? trialStartDate;
  final DateTime? trialEndDate;
  final DateTime? subscriptionStartDate;
  final DateTime? subscriptionEndDate;
  final bool isTrialUsed;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Subscription({
    required this.id,
    required this.businessId,
    this.planId,
    required this.status,
    this.trialStartDate,
    this.trialEndDate,
    this.subscriptionStartDate,
    this.subscriptionEndDate,
    this.isTrialUsed = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) => Subscription(
        id: json['id'] as String,
        businessId: json['business_id'] as String,
        planId: json['plan_id'] as String?,
        status: json['status'] as String,
        trialStartDate: json['trial_start_date'] != null
            ? DateTime.parse(json['trial_start_date'] as String)
            : null,
        trialEndDate: json['trial_end_date'] != null
            ? DateTime.parse(json['trial_end_date'] as String)
            : null,
        subscriptionStartDate: json['subscription_start_date'] != null
            ? DateTime.parse(json['subscription_start_date'] as String)
            : null,
        subscriptionEndDate: json['subscription_end_date'] != null
            ? DateTime.parse(json['subscription_end_date'] as String)
            : null,
        isTrialUsed: json['is_trial_used'] as bool? ?? false,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'business_id': businessId,
        'plan_id': planId,
        'status': status,
        'trial_start_date': trialStartDate?.toIso8601String(),
        'trial_end_date': trialEndDate?.toIso8601String(),
        'subscription_start_date': subscriptionStartDate?.toIso8601String(),
        'subscription_end_date': subscriptionEndDate?.toIso8601String(),
        'is_trial_used': isTrialUsed,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  // Computed properties
  bool get isActive => status == AppConstants.statusActive;
  bool get isTrialActive => status == AppConstants.statusTrialActive;
  bool get isTrialExpired => status == AppConstants.statusTrialExpired;
  bool get isExpired => status == AppConstants.statusExpired || status == AppConstants.statusTrialExpired;
  bool get hasAccess => isActive || isTrialActive;

  int get trialDaysLeft {
    if (trialEndDate == null) return 0;
    final diff = trialEndDate!.difference(DateTime.now()).inDays;
    return diff.clamp(0, AppConstants.trialDays);
  }

  int get subscriptionDaysLeft {
    if (subscriptionEndDate == null) return 0;
    final diff = subscriptionEndDate!.difference(DateTime.now()).inDays;
    return diff.clamp(0, 400);
  }
}

class SubscriptionPlan {
  final String id;
  final String name;
  final String interval;
  final double price;
  final String? description;
  final List<String> features;
  final bool isActive;

  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.interval,
    required this.price,
    this.description,
    this.features = const [],
    this.isActive = true,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) => SubscriptionPlan(
        id: json['id'] as String,
        name: json['name'] as String,
        interval: json['interval'] as String,
        price: (json['price'] as num).toDouble(),
        description: json['description'] as String?,
        features: (json['features'] as List<dynamic>?)?.cast<String>() ?? [],
        isActive: json['is_active'] as bool? ?? true,
      );
}
