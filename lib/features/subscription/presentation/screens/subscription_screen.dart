import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smart_saoji/core/theme/app_theme.dart';
import 'package:smart_saoji/core/widgets/app_button.dart';
import 'package:smart_saoji/core/widgets/app_snackbar.dart';
import 'package:smart_saoji/features/subscription/data/models/subscription_model.dart';
import 'package:smart_saoji/features/subscription/presentation/providers/subscription_provider.dart';
import 'package:smart_saoji/features/subscription/data/services/subscription_manager.dart';
import 'package:smart_saoji/core/l10n/app_strings.dart';

// ── Providers for Payment Request Flow ─────────────────────────────

final pendingPaymentRequestProvider = FutureProvider.autoDispose<Map<String, dynamic>?>((ref) async {
  final supabase = Supabase.instance.client;
  final userId = supabase.auth.currentUser?.id;
  if (userId == null) return null;
  
  final res = await supabase
      .from('payment_requests')
      .select('id, plan_code, amount, status, screenshot_url, created_at')
      .eq('user_id', userId)
      .eq('status', 'pending')
      .maybeSingle();
      
  return res;
});

final latestRejectedPaymentRequestProvider = FutureProvider.autoDispose<Map<String, dynamic>?>((ref) async {
  final supabase = Supabase.instance.client;
  final userId = supabase.auth.currentUser?.id;
  if (userId == null) return null;
  
  final res = await supabase
      .from('payment_requests')
      .select('id, plan_code, amount, status, rejection_reason, updated_at')
      .eq('user_id', userId)
      .eq('status', 'rejected')
      .order('updated_at', ascending: false)
      .limit(1)
      .maybeSingle();
      
  return res;
});

// ── Subscription Screen ──────────────────────────────────────────

class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  void _showPaymentModal(BuildContext context, SubscriptionPlan plan) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ManualPaymentModal(plan: plan, ref: ref),
    );
  }

  @override
  Widget build(BuildContext context) {
    final manager = ref.watch(subscriptionManagerProvider);
    final plansAsync = ref.watch(subscriptionPlansProvider);
    final pendingRequestAsync = ref.watch(pendingPaymentRequestProvider);
    final rejectedRequestAsync = ref.watch(latestRejectedPaymentRequestProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Plans & Pricing'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              ref.read(subscriptionManagerProvider.notifier).syncSubscription();
              ref.invalidate(subscriptionPlansProvider);
              ref.invalidate(pendingPaymentRequestProvider);
              ref.invalidate(latestRejectedPaymentRequestProvider);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(subscriptionManagerProvider.notifier).syncSubscription();
          ref.invalidate(subscriptionPlansProvider);
          ref.invalidate(pendingPaymentRequestProvider);
          ref.invalidate(latestRejectedPaymentRequestProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Current Status Card
              _CurrentPlanCard(manager: manager),
              const SizedBox(height: 16),

              // Pending / Rejected Status Info
              pendingRequestAsync.when(
                data: (req) => req != null
                    ? _PendingRequestCard(request: req)
                    : const SizedBox.shrink(),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),

              rejectedRequestAsync.when(
                data: (req) => req != null
                    ? _RejectedRequestCard(request: req)
                    : const SizedBox.shrink(),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),

              const SizedBox(height: 16),
              Text(
                context.l10n.chooseUpgradePlan,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ).animate().fadeIn(),
              const SizedBox(height: 4),
              Text(
                context.l10n.selectPlanSubtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.lightTextSecondary,
                    ),
              ).animate(delay: 50.ms).fadeIn(),
              const SizedBox(height: 20),

              // Dynamic Plans List
              plansAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (err, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Text('Failed to load plans: $err'),
                  ),
                ),
                data: (plans) {
                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: plans.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final plan = plans[index];
                      final isCurrentPlan = manager.planCode == plan.planCode;
                      final isBestValue = plan.planCode == 'diamond';
                      return _PremiumPlanCard(
                        plan: plan,
                        isCurrent: isCurrentPlan,
                        isBestValue: isBestValue,
                        onSelect: () {
                          if (plan.price == 0) {
                            AppSnackbar.show(
                              context,
                              'You are already on the Free Plan.',
                              isError: true,
                            );
                            return;
                          }
                          _showPaymentModal(context, plan);
                        },
                      ).animate(delay: Duration(milliseconds: 100 + index * 60))
                       .fadeIn()
                       .slideY(begin: 0.1, end: 0);
                    },
                  );
                },
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Current Plan Card ───────────────────────────────────────────

class _CurrentPlanCard extends StatelessWidget {
  final SubscriptionState manager;
  const _CurrentPlanCard({required this.manager});

  @override
  Widget build(BuildContext context) {
    final planName = manager.planCode.toUpperCase();
    final isActive = manager.isActive;
    final hasExpiry = manager.expiryDate != null;
    final expiryStr = hasExpiry
        ? DateFormat('dd MMM yyyy').format(manager.expiryDate!)
        : 'Lifetime';

    Color cardColor = AppTheme.primaryColor;
    if (manager.planCode == 'gold') cardColor = const Color(0xFFF59E0B);
    if (manager.planCode == 'diamond') cardColor = const Color(0xFF8B5CF6);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cardColor.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: cardColor.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cardColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              manager.planCode == 'basic'
                  ? Icons.star_border_rounded
                  : Icons.workspace_premium_rounded,
              color: cardColor,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CURRENT PLAN',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppTheme.lightTextHint,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$planName Plan',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  hasExpiry ? 'Expires: $expiryStr' : 'Status: Free Forever',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.lightTextSecondary,
                      ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isActive ? AppTheme.successColor.withValues(alpha: 0.1) : AppTheme.errorColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isActive ? 'Active' : 'Expired',
              style: TextStyle(
                color: isActive ? AppTheme.successColor : AppTheme.errorColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Pending Payment Request Card ─────────────────────────────────

class _PendingRequestCard extends StatelessWidget {
  final Map<String, dynamic> request;
  const _PendingRequestCard({required this.request});

  @override
  Widget build(BuildContext context) {
    final createdStr = DateFormat('dd MMM yyyy, hh:mm a')
        .format(DateTime.parse(request['created_at'] as String).toLocal());
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.hourglass_empty_rounded, color: Color(0xFFD97706), size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Payment Request Pending Approval',
                  style: TextStyle(
                    color: Color(0xFF92400E),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your request for ${(request['plan_code'] as String).toUpperCase()} (Rs. ${request['amount']}) is awaiting admin verification.',
                  style: const TextStyle(
                    color: Color(0xFFB45309),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Submitted: $createdStr',
                  style: const TextStyle(
                    color: Color(0xFFD97706),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1, end: 0);
  }
}

// ── Rejected Payment Request Card ─────────────────────────────────

class _RejectedRequestCard extends StatelessWidget {
  final Map<String, dynamic> request;
  const _RejectedRequestCard({required this.request});

  @override
  Widget build(BuildContext context) {
    final reason = request['rejection_reason'] as String? ?? 'No reason provided';
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.cancel_outlined, color: Color(0xFFB91C1C), size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Previous Request Rejected',
                  style: TextStyle(
                    color: Color(0xFF991B1B),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Reason: $reason',
                  style: const TextStyle(
                    color: Color(0xFFB91C1C),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1, end: 0);
  }
}

// ── Premium Plan Card ──────────────────────────────────────────

class _PremiumPlanCard extends StatelessWidget {
  final SubscriptionPlan plan;
  final bool isCurrent;
  final bool isBestValue;
  final VoidCallback onSelect;

  const _PremiumPlanCard({
    required this.plan,
    required this.isCurrent,
    required this.isBestValue,
    required this.onSelect,
  });

  Widget _buildLimitsSection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Map of limits per plan
    final Map<String, List<Map<String, dynamic>>> limits = {
      'basic': [
        {'label': 'Add Party', 'limit': 'Max 5 / day', 'icon': Icons.people_outline},
        {'label': 'Add Transaction', 'limit': 'Max 10 / day', 'icon': Icons.receipt_long_outlined},
        {'label': 'Add Expense', 'limit': 'Max 10 / day', 'icon': Icons.wallet_outlined},
        {'label': 'Add Product', 'limit': 'Max 5 / day', 'icon': Icons.inventory_2_outlined},
      ],
      'gold': [
        {'label': 'Add Party', 'limit': 'Max 10 / day', 'icon': Icons.people_outline},
        {'label': 'Add Transaction', 'limit': 'Max 50 / day', 'icon': Icons.receipt_long_outlined},
        {'label': 'Add Expense', 'limit': 'Max 50 / day', 'icon': Icons.wallet_outlined},
        {'label': 'Add Product', 'limit': 'Max 20 / day', 'icon': Icons.inventory_2_outlined},
      ],
      'diamond': [
        {'label': 'Add Party', 'limit': 'Unlimited', 'icon': Icons.people_outline},
        {'label': 'Add Transaction', 'limit': 'Unlimited', 'icon': Icons.receipt_long_outlined},
        {'label': 'Add Expense', 'limit': 'Unlimited', 'icon': Icons.wallet_outlined},
        {'label': 'Add Product', 'limit': 'Unlimited', 'icon': Icons.inventory_2_outlined},
      ],
    };

    final planLimits = limits[plan.planCode] ?? limits['basic']!;
    
    Color activeColor = AppTheme.primaryColor;
    if (plan.planCode == 'gold') activeColor = const Color(0xFFF59E0B);
    if (plan.planCode == 'diamond') activeColor = const Color(0xFF8B5CF6);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: activeColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: activeColor.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.speed_rounded, size: 16, color: activeColor),
              const SizedBox(width: 8),
              Text(
                'DAILY USAGE LIMITS',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: activeColor,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...planLimits.map((limitItem) {
            final String lStr = limitItem['limit'] as String;
            final isUnlimited = lStr.toLowerCase() == 'unlimited';
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(
                    limitItem['icon'] as IconData,
                    size: 15,
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    limitItem['label'] as String,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isUnlimited 
                          ? AppTheme.successColor.withValues(alpha: 0.12)
                          : activeColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      lStr,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isUnlimited ? AppTheme.successColor : activeColor,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Color activeColor = AppTheme.primaryColor;
    if (plan.id == 'gold') activeColor = const Color(0xFFF59E0B);
    if (plan.id == 'diamond') activeColor = const Color(0xFF8B5CF6);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCurrent
              ? activeColor
              : isBestValue
                  ? activeColor.withValues(alpha: 0.5)
                  : AppTheme.lightBorder,
          width: isCurrent || isBestValue ? 2 : 1,
        ),
        boxShadow: isBestValue
            ? [
                BoxShadow(
                  color: activeColor.withValues(alpha: 0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                )
              ]
            : [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isBestValue)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [activeColor, activeColor.withValues(alpha: 0.8)],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.star, color: Colors.white, size: 14),
                  SizedBox(width: 4),
                  Text(
                    'MOST POPULAR & FULL ACCESS',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      letterSpacing: 1.1,
                    ),
                  ),
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
                        Text(
                          plan.name,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          plan.interval == 'forever' ? 'Pay once' : 'Per year',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.lightTextSecondary,
                              ),
                        ),
                      ],
                    ),
                    Text(
                      plan.price == 0 ? 'FREE' : 'Rs. ${plan.price.toInt()}',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: activeColor,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),
                
                // Gorgeous limits box
                _buildLimitsSection(context),
                
                ...plan.features.map((f) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.check_circle_outline_rounded,
                              color: AppTheme.successColor, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              f,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontSize: 13,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    )),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isCurrent ? null : onSelect,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isCurrent ? Colors.grey : activeColor,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      isCurrent ? 'Current Plan' : 'Select ${plan.name}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
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

// ── Manual Payment bottom Modal Sheet ───────────────────────────

class _ManualPaymentModal extends StatefulWidget {
  final SubscriptionPlan plan;
  final WidgetRef ref;
  const _ManualPaymentModal({required this.plan, required this.ref});

  @override
  State<_ManualPaymentModal> createState() => _ManualPaymentModalState();
}

class _ManualPaymentModalState extends State<_ManualPaymentModal> {
  XFile? _imageFile;
  bool _isLoading = false;
  String _paymentMethod = 'esewa'; // 'esewa', 'khalti', 'bank'

  String _getQRAssetPath() {
    if (_paymentMethod == 'esewa') {
      return 'assets/images/esewaqr.jpeg';
    } else if (_paymentMethod == 'khalti') {
      return 'assets/images/khaltiqr.jpeg';
    } else {
      return 'assets/images/prabhubankqr.jpeg';
    }
  }

  void _showZoomedQR(BuildContext context, String assetPath) {
    final methodLabel = _paymentMethod == 'esewa'
        ? 'eSewa QR Code'
        : _paymentMethod == 'khalti'
            ? 'Khalti QR Code'
            : 'Prabhu Bank QR Code';

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (dialogCtx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 520),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      methodLabel,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black87),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.black54),
                      onPressed: () => Navigator.pop(dialogCtx),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // QR image — constrained, never overflows
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 300,
                      maxHeight: 300,
                    ),
                    child: Image.asset(
                      assetPath,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const SizedBox(
                        width: 200,
                        height: 200,
                        child: Center(
                          child: Icon(Icons.qr_code_2_rounded,
                              size: 100, color: Colors.black54),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.qr_code_scanner_rounded,
                          size: 16, color: Colors.black54),
                      SizedBox(width: 6),
                      Text(
                        'Scan with your payment app to pay',
                        style: TextStyle(color: Colors.black54, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMethodCard(String method, String label, String? imagePath, {IconData? icon}) {
    final isSelected = _paymentMethod == method;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color activeColor = AppTheme.primaryColor;
    if (method == 'esewa') activeColor = const Color(0xFF60BB46);
    if (method == 'khalti') activeColor = const Color(0xFF5C2D91);
    if (method == 'bank') activeColor = const Color(0xFFC2185B);

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _paymentMethod = method;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? activeColor.withValues(alpha: 0.08)
                : (isDark ? Colors.grey.shade900 : Colors.grey.shade50),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? activeColor : (isDark ? Colors.grey.shade800 : Colors.grey.shade200),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              if (imagePath != null)
                Image.asset(
                  imagePath,
                  height: 24,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Icon(icon ?? Icons.payment, size: 24, color: activeColor),
                )
              else
                Icon(icon ?? Icons.payment, size: 24, color: activeColor),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? activeColor : (isDark ? Colors.white70 : Colors.black87),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await ImagePicker().pickImage(source: source);
      if (picked != null) {
        setState(() => _imageFile = picked);
      }
    } catch (e) {
      if (mounted) AppSnackbar.show(context, 'Failed to pick image', isError: true);
    }
  }

  Future<void> _submitRequest() async {
    if (_imageFile == null) {
      AppSnackbar.show(context, context.l10n.uploadScreenshot, isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser!.id;

      // 1. Upload receipt to Supabase Storage
      final bytes = await _imageFile!.readAsBytes();
      final ext = _imageFile!.name.split('.').last;
      final filename = '${userId}_${DateTime.now().millisecondsSinceEpoch}.$ext';

      await supabase.storage
          .from('receipt-images')
          .uploadBinary(filename, bytes);

      final screenshotUrl = supabase.storage
          .from('receipt-images')
          .getPublicUrl(filename);

      // 2. Insert into payment_requests table
      await supabase.from('payment_requests').insert({
        'user_id': userId,
        'plan_code': widget.plan.planCode,
        'amount': widget.plan.price,
        'screenshot_url': screenshotUrl,
        'status': 'pending',
      });

      // 3. Immediately trigger email queue so user + admin get notified
      try {
        await supabase.functions.invoke(
          'send-email',
          body: {'action': 'process_queue'},
        );
      } catch (e) {
        debugPrint('Email queue trigger (non-fatal): $e');
      }

      if (mounted) {
        AppSnackbar.show(
          context,
          context.l10n.paymentSuccessMsg,
          isSuccess: true,
        );
        widget.ref.invalidate(pendingPaymentRequestProvider);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.show(context, 'Error submitting payment: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              context.l10n.payUpgrade,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              context.l10n.submitManualRequestFor(widget.plan.name),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.lightTextSecondary,
                  ),
            ),
            const Divider(height: 24),

            Text(
              context.l10n.choosePaymentMethod,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppTheme.lightTextHint,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildMethodCard('esewa', 'eSewa', 'assets/images/esewa.png'),
                const SizedBox(width: 8),
                _buildMethodCard('khalti', 'Khalti', 'assets/images/khalti.png'),
                const SizedBox(width: 8),
                _buildMethodCard('bank', 'Prabhu Bank', null, icon: Icons.account_balance_rounded),
              ],
            ),
            const SizedBox(height: 20),

            // Bank/Wallet details and QR area
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_paymentMethod == 'bank') ...[
                        Text(
                          context.l10n.bankDepositDetails,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.lightTextHint,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Prabhu Bank Limited',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFFC2185B)),
                        ),
                        const SizedBox(height: 4),
                        Text('${context.l10n.acName} AAKASH YADAV', style: const TextStyle(fontWeight: FontWeight.w500)),
                        Text('${context.l10n.acNo} 0710169966400018'),
                        Text('${context.l10n.branch} Hetauda'),
                      ] else if (_paymentMethod == 'esewa') ...[
                        Text(
                          context.l10n.esewaDetails,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.lightTextHint,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'eSewa Nepal',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF60BB46)),
                        ),
                        const SizedBox(height: 4),
                        Text('${context.l10n.acName} AAKASH YADAV', style: const TextStyle(fontWeight: FontWeight.w500)),
                        Text(context.l10n.scanQrToPayInstantly),
                      ] else ...[
                        Text(
                          context.l10n.khaltiDetails,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.lightTextHint,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Khalti Wallet',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF5C2D91)),
                        ),
                        const SizedBox(height: 4),
                        Text('${context.l10n.acName} AAKASH YADAV', style: const TextStyle(fontWeight: FontWeight.w500)),
                        Text(context.l10n.scanQrToPayInstantly),
                      ],
                      const SizedBox(height: 12),
                      Text(
                        context.l10n.amountToPay(widget.plan.price.toInt()),
                        style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // QR code box
                GestureDetector(
                  onTap: () => _showZoomedQR(context, _getQRAssetPath()),
                  child: Container(
                    width: 110,
                    height: 110,
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: Image.asset(
                      _getQRAssetPath(),
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Center(
                        child: Icon(Icons.qr_code_2_rounded, size: 60, color: Colors.black54),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
            Text(
              context.l10n.paymentProof,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppTheme.lightTextHint,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 10),

            // Screenshot selector / preview
            if (_imageFile == null)
              GestureDetector(
                onTap: () => _pickImage(ImageSource.gallery),
                child: Container(
                  height: 130,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.primaryColor.withValues(alpha: 0.2),
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_photo_alternate_outlined,
                          color: AppTheme.primaryColor, size: 36),
                      const SizedBox(height: 8),
                      Text(
                        context.l10n.uploadScreenshot,
                        style: const TextStyle(color: AppTheme.primaryColor, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              )
            else
              Stack(
                children: [
                  Container(
                    height: 140,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: kIsWeb
                          ? Image.network(_imageFile!.path, fit: BoxFit.cover)
                          : Image.file(io.File(_imageFile!.path), fit: BoxFit.cover),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: CircleAvatar(
                      backgroundColor: Colors.black54,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => setState(() => _imageFile = null),
                      ),
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(context.l10n.cancel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton(
                    label: context.l10n.submitProof,
                    onPressed: _submitRequest,
                    isLoading: _isLoading,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
