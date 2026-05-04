import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_button.dart';
import '../providers/subscription_provider.dart';
import '../models/subscription.dart';

class SubscriptionScreen extends ConsumerWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subAsync = ref.watch(subscriptionProvider);

    return Scaffold(
      appBar: context.canPop() ? AppBar(title: const Text('Subscription Plans')) : null,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              children: [
                // Header
                const SizedBox(height: 16),
                const Icon(Icons.workspace_premium_rounded,
                    size: 56, color: AppColors.accent),
                const SizedBox(height: 16),
                Text('Choose Your Plan',
                    style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text('Start free, upgrade anytime',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 32),

                // Free Trial Card
                _PlanCard(
                  title: 'Free Trial',
                  subtitle: '14 Days',
                  price: 'FREE',
                  priceNote: 'No credit card required',
                  color: AppColors.success,
                  icon: Icons.emoji_events_rounded,
                  features: const [
                    'Basic POS Billing',
                    'Up to 50 Products',
                    'Up to 20 Customers',
                    'Basic Reports',
                  ],
                  isRecommended: false,
                  onTap: () => _selectPlan(
                      context, ref, SubscriptionPlan.free),
                ),
                const SizedBox(height: 16),

                // Monthly
                _PlanCard(
                  title: 'Monthly',
                  subtitle: 'Per month',
                  price: 'NPR 250',
                  priceNote: 'Billed monthly',
                  color: AppColors.primary,
                  icon: Icons.calendar_month_rounded,
                  features: const [
                    'Unlimited Billing & Products',
                    'Customer Ledger',
                    'Inventory Management',
                    'Reports & Analytics',
                    'Data Export (CSV/PDF)',
                    'Email Support',
                  ],
                  isRecommended: false,
                  onTap: () => _selectPlan(
                      context, ref, SubscriptionPlan.monthly),
                ),
                const SizedBox(height: 16),

                // 6 Month – Recommended
                _PlanCard(
                  title: '6 Months',
                  subtitle: 'Save 13%',
                  price: 'NPR 1,299',
                  priceNote: '≈ NPR 217/month',
                  color: AppColors.accent,
                  icon: Icons.local_fire_department_rounded,
                  features: const [
                    'Everything in Monthly',
                    'Supplier Management',
                    'Expense Tracking',
                    'Profit & Loss Reports',
                    'Backup & Restore',
                    'Priority Support',
                  ],
                  isRecommended: true,
                  onTap: () => _selectPlan(
                      context, ref, SubscriptionPlan.sixMonth),
                ),
                const SizedBox(height: 16),

                // Yearly
                _PlanCard(
                  title: 'Yearly',
                  subtitle: 'Best Value – Save 24%',
                  price: 'NPR 2,299',
                  priceNote: '≈ NPR 192/month',
                  color: AppColors.posColor,
                  icon: Icons.diamond_rounded,
                  features: const [
                    'Everything in 6 Months',
                    'Multi-Staff Support',
                    'Barcode Scanner',
                    'Advanced Analytics',
                    'WhatsApp Reminders',
                    'Dedicated Support',
                  ],
                  isRecommended: false,
                  onTap: () => _selectPlan(
                      context, ref, SubscriptionPlan.yearly),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _selectPlan(
      BuildContext context, WidgetRef ref, SubscriptionPlan plan) async {
    await ref.read(subscriptionProvider.notifier).activate(plan);
    if (context.mounted) {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(AppConstants.routeDashboard);
      }
    }
  }
}

class _PlanCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String price;
  final String priceNote;
  final Color color;
  final IconData icon;
  final List<String> features;
  final bool isRecommended;
  final VoidCallback onTap;

  const _PlanCard({
    required this.title,
    required this.subtitle,
    required this.price,
    required this.priceNote,
    required this.color,
    required this.icon,
    required this.features,
    required this.isRecommended,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border.all(
                color: isRecommended ? color : AppColors.border,
                width: isRecommended ? 2 : 1),
            borderRadius: BorderRadius.circular(20),
            color: Theme.of(context).cardColor,
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.w700)),
                        Text(subtitle,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(price,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                  color: color,
                                  fontWeight: FontWeight.w700)),
                      Text(priceNote,
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(color: AppColors.textHint)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...features.map((f) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle_rounded,
                            size: 18, color: color),
                        const SizedBox(width: 8),
                        Text(f,
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  )),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onTap,
                  style: ElevatedButton.styleFrom(backgroundColor: color),
                  child: Text('Get Started'),
                ),
              ),
            ],
          ),
        ),
        if (isRecommended)
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('RECOMMENDED',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700)),
            ),
          ),
      ],
    );
  }
}
