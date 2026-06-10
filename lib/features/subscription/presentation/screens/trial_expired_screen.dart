import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_saoji/core/router/app_router.dart';
import 'package:smart_saoji/core/theme/app_theme.dart';
import 'package:smart_saoji/core/widgets/app_button.dart';

class TrialExpiredScreen extends StatelessWidget {
  const TrialExpiredScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Illustration
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppTheme.warningColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.timer_off_outlined,
                      size: 56, color: AppTheme.warningColor),
                )
                    .animate()
                    .scale(duration: 600.ms, curve: Curves.elasticOut)
                    .fadeIn(),

                const SizedBox(height: 32),

                Text('Your Free Trial Has Ended',
                        style: Theme.of(context).textTheme.headlineMedium,
                        textAlign: TextAlign.center)
                    .animate(delay: 200.ms)
                    .fadeIn()
                    .slideY(begin: 0.2, end: 0),

                const SizedBox(height: 12),

                Text(
                  'Your 14-day free trial has expired. Subscribe to continue accessing all features and keep your data safe.',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppTheme.lightTextSecondary),
                  textAlign: TextAlign.center,
                ).animate(delay: 300.ms).fadeIn(),

                const SizedBox(height: 40),

                // Feature list
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: AppTheme.primaryColor.withValues(alpha: 0.15)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('What you\'ll get with a subscription:',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(color: AppTheme.primaryColor)),
                      const SizedBox(height: 14),
                      ...[
                        'Unlimited sales & purchase records',
                        'Full inventory management',
                        'Customer & supplier ledger',
                        'Professional invoice generation',
                        'Detailed business reports',
                        'Offline mode with auto-sync',
                        'Staff management & permissions',
                      ].map((f) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle_rounded,
                                    color: AppTheme.successColor, size: 18),
                                const SizedBox(width: 10),
                                Expanded(
                                    child: Text(f,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium)),
                              ],
                            ),
                          )),
                    ],
                  ),
                ).animate(delay: 400.ms).fadeIn().slideY(begin: 0.1, end: 0),

                const SizedBox(height: 32),

                // Pricing preview
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primaryColor, AppTheme.primaryDark],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Monthly Plan',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 13)),
                          Text('Rs. 499/month',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 20)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Yearly Plan',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 13)),
                          const Text('Rs. 4,499/year',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 20)),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                                color: AppTheme.accentColor,
                                borderRadius: BorderRadius.circular(4)),
                            child: const Text('SAVE 25%',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ).animate(delay: 500.ms).fadeIn(),

                const SizedBox(height: 24),

                AppButton(
                  label: 'Subscribe Now',
                  icon: Icons.rocket_launch_outlined,
                  onPressed: () => context.push(AppRoutes.subscription),
                ).animate(delay: 600.ms).fadeIn().slideY(begin: 0.1, end: 0),

                const SizedBox(height: 12),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () => context.push(AppRoutes.settings),
                      child: const Text('Profile & Settings'),
                    ),
                    const Text('•',
                        style: TextStyle(color: AppTheme.lightTextHint)),
                    TextButton(
                      onPressed: () {},
                      child: const Text('Contact Support'),
                    ),
                  ],
                ).animate(delay: 700.ms).fadeIn(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
