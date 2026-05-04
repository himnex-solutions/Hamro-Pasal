enum SubscriptionPlan { free, monthly, sixMonth, yearly }
enum SubscriptionStatus { active, expired, trial, cancelled }

class Subscription {
  final String id;
  final String userId;
  final SubscriptionPlan planType;
  final DateTime startDate;
  final DateTime endDate;
  final SubscriptionStatus status;
  final String? paymentMethod;
  final String? transactionId;
  final DateTime createdAt;

  const Subscription({
    required this.id,
    required this.userId,
    required this.planType,
    required this.startDate,
    required this.endDate,
    required this.status,
    this.paymentMethod,
    this.transactionId,
    required this.createdAt,
  });

  bool get isActive =>
      status == SubscriptionStatus.active &&
      endDate.isAfter(DateTime.now());

  bool get isTrial => status == SubscriptionStatus.trial;

  int get daysRemaining =>
      endDate.difference(DateTime.now()).inDays.clamp(0, 9999);

  factory Subscription.fromJson(Map<String, dynamic> json) => Subscription(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        planType: _parsePlan(json['plan_type'] as String),
        startDate: DateTime.parse(json['start_date'] as String),
        endDate: DateTime.parse(json['end_date'] as String),
        status: _parseStatus(json['status'] as String),
        paymentMethod: json['payment_method'] as String?,
        transactionId: json['transaction_id'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'plan_type': planType.name,
        'start_date': startDate.toIso8601String(),
        'end_date': endDate.toIso8601String(),
        'status': status.name,
        'payment_method': paymentMethod,
        'transaction_id': transactionId,
      };

  static SubscriptionPlan _parsePlan(String v) =>
      SubscriptionPlan.values.firstWhere((e) => e.name == v,
          orElse: () => SubscriptionPlan.free);

  static SubscriptionStatus _parseStatus(String v) =>
      SubscriptionStatus.values.firstWhere((e) => e.name == v,
          orElse: () => SubscriptionStatus.expired);
}
