import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hamro_pasal/core/theme/app_theme.dart';
import 'package:hamro_pasal/features/subscription/data/models/subscription_model.dart';
import 'package:hamro_pasal/features/subscription/presentation/providers/subscription_provider.dart';

class SubscriptionScreen extends ConsumerWidget {
  const SubscriptionScreen({super.key});

  static const _plans = [
    _Plan('Monthly Plan', 'monthly', 499, [
      'Unlimited sales & purchases',
      'Inventory management',
      'Party ledger',
      'Invoice generation',
      'Expense tracking',
      'Reports & export',
      'Staff management (up to 3)',
      'Offline mode',
    ]),
    _Plan(
        'Yearly Plan',
        'yearly',
        4499,
        [
          'Everything in Monthly',
          'Save Rs. 1,489 vs monthly',
          'Staff management (unlimited)',
          'Priority support',
          'Data backup & restore',
          'Custom invoice branding',
        ],
        isBestValue: true),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subAsync = ref.watch(subscriptionProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Subscription')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current status
            subAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (sub) =>
                  sub != null ? _StatusCard(sub: sub) : const SizedBox.shrink(),
            ),
            const SizedBox(height: 24),

            Text('Choose Your Plan',
                    style: Theme.of(context).textTheme.headlineMedium)
                .animate()
                .fadeIn(),
            const SizedBox(height: 6),
            Text('Unlock full access to Hamro Pasal',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: AppTheme.lightTextSecondary))
                .animate(delay: 50.ms)
                .fadeIn(),
            const SizedBox(height: 20),

            ..._plans.asMap().entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _PlanCard(plan: entry.value)
                    .animate(
                        delay: Duration(milliseconds: 100 + entry.key * 80))
                    .fadeIn()
                    .slideY(begin: 0.1, end: 0),
              );
            }),

            const SizedBox(height: 16),

            // Payment methods
            Text('Payment Methods',
                    style: Theme.of(context).textTheme.titleLarge)
                .animate(delay: 260.ms)
                .fadeIn(),
            const SizedBox(height: 12),
            const Row(
              children: [
                _PaymentMethodChip(
                    'Khalti', 'assets/images/khalti.png', Color(0xFF5C2D91)),
                SizedBox(width: 12),
                _PaymentMethodChip(
                    'eSewa', 'assets/images/esewa.png', Color(0xFF60BB46)),
              ],
            ).animate(delay: 300.ms).fadeIn(),

            const SizedBox(height: 24),

            // Contact support
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: AppTheme.primaryColor.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.support_agent_outlined,
                      color: AppTheme.primaryColor, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Need Help?',
                            style: Theme.of(context).textTheme.titleMedium),
                        Text(
                            'Contact our support team for assistance with subscription.',
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                  TextButton(onPressed: () {}, child: const Text('Contact')),
                ],
              ),
            ).animate(delay: 350.ms).fadeIn(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final Subscription sub;
  const _StatusCard({required this.sub});

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (sub.status) {
      case 'trial_active':
        statusColor = AppTheme.infoColor;
        statusIcon = Icons.rocket_launch_outlined;
        statusText = 'Free Trial Active • ${sub.trialDaysLeft} days left';
        break;
      case 'active':
        statusColor = AppTheme.successColor;
        statusIcon = Icons.verified_outlined;
        statusText = 'Subscription Active';
        break;
      case 'trial_expired':
        statusColor = AppTheme.warningColor;
        statusIcon = Icons.timer_off_outlined;
        statusText = 'Trial Expired';
        break;
      default:
        statusColor = AppTheme.errorColor;
        statusIcon = Icons.cancel_outlined;
        statusText = sub.status.replaceAll('_', ' ').toUpperCase();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          statusColor.withValues(alpha: 0.1),
          statusColor.withValues(alpha: 0.05)
        ]),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 28),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Current Status',
                  style: Theme.of(context).textTheme.bodySmall),
              Text(statusText,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: statusColor)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Plan {
  final String name, interval;
  final int price;
  final List<String> features;
  final bool isBestValue;
  const _Plan(this.name, this.interval, this.price, this.features,
      {this.isBestValue = false});
}

class _PlanCard extends StatelessWidget {
  final _Plan plan;
  const _PlanCard({required this.plan});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color:
              plan.isBestValue ? AppTheme.primaryColor : AppTheme.lightBorder,
          width: plan.isBestValue ? 2 : 1,
        ),
        boxShadow: plan.isBestValue
            ? [
                BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 4))
              ]
            : [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (plan.isBestValue)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: const BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.star, color: Colors.white, size: 14),
                  const SizedBox(width: 4),
                  const Text('BEST VALUE — SAVE 25%',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13)),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(plan.name,
                            style: Theme.of(context).textTheme.titleLarge),
                        Text(
                            plan.interval == 'monthly'
                                ? 'Per month'
                                : 'Per year',
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Rs. ${plan.price}',
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),
                ...plan.features.map((f) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_outline,
                              color: AppTheme.successColor, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                              child: Text(f,
                                  style:
                                      Theme.of(context).textTheme.bodyMedium)),
                        ],
                      ),
                    )),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          plan.isBestValue ? AppTheme.primaryColor : null,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                        'Subscribe — Rs. ${plan.price}/${plan.interval == 'monthly' ? 'mo' : 'yr'}'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentMethodChip extends StatelessWidget {
  final String name, imagePath;
  final Color color;
  const _PaymentMethodChip(this.name, this.imagePath, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            imagePath, 
            height: 24, 
            width: 70, 
            fit: BoxFit.contain,
          ),
        ],
      ),
    );
  }
}
