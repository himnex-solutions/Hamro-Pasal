import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smart_saoji/core/constants/app_constants.dart';
import 'package:smart_saoji/core/router/app_router.dart';
import 'package:smart_saoji/core/theme/app_theme.dart';
import 'package:smart_saoji/core/widgets/poly_mesh_background.dart';

// ── Personal Stats Model ─────────────────────────────────────
class PersonalStats {
  final String fullName;
  final String email;
  final String phone;
  final String businessName;
  final String businessType;
  final String subscriptionStatus;
  final int? trialDaysLeft;
  final double totalBusinessSales;
  final double totalBusinessExpenses;
  final int totalParties;
  final int totalProducts;

  const PersonalStats({
    this.fullName = '',
    this.email = '',
    this.phone = '',
    this.businessName = '',
    this.businessType = '',
    this.subscriptionStatus = 'active',
    this.trialDaysLeft,
    this.totalBusinessSales = 0,
    this.totalBusinessExpenses = 0,
    this.totalParties = 0,
    this.totalProducts = 0,
  });
}

// ── Provider ─────────────────────────────────────────────────
final personalDashboardProvider =
    AsyncNotifierProvider<PersonalDashboardNotifier, PersonalStats>(() {
  return PersonalDashboardNotifier();
});

class PersonalDashboardNotifier extends AsyncNotifier<PersonalStats> {
  @override
  Future<PersonalStats> build() => _fetch();

  Future<PersonalStats> _fetch() async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return const PersonalStats();

    try {
      // Fetch user profile
      final profile = await supabase
          .from('user_profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      // Fetch business (first business the user owns/belongs to)
      final memberRow = await supabase
          .from('business_members')
          .select('business_id')
          .eq('user_id', userId)
          .limit(1)
          .maybeSingle();

      String businessName = '';
      String businessType = '';
      String subStatus = AppConstants.statusActive;
      int? trialDaysLeft;
      double totalSales = 0, totalExpenses = 0;
      int totalParties = 0, totalProducts = 0;

      final businessId = memberRow?['business_id'] as String?;
      if (businessId != null) {
        final biz = await supabase
            .from('businesses')
            .select('name, type')
            .eq('id', businessId)
            .maybeSingle();
        businessName = biz?['name'] as String? ?? '';
        businessType = biz?['type'] as String? ?? '';

        // Subscription
        final sub = await supabase
            .from('subscriptions')
            .select('status, trial_end_date')
            .eq('business_id', businessId)
            .maybeSingle();
        if (sub != null) {
          subStatus = sub['status'] as String? ?? AppConstants.statusActive;
          if (sub['trial_end_date'] != null) {
            final end = DateTime.parse(sub['trial_end_date'] as String);
            trialDaysLeft = end.difference(DateTime.now()).inDays;
          }
        }

        // Lifetime sales & expenses
        final txRes = await supabase
            .from('transactions')
            .select('type, amount')
            .eq('business_id', businessId);
        for (final tx in txRes as List) {
          final amount = (tx['amount'] as num).toDouble();
          if (tx['type'] == AppConstants.txSale) totalSales += amount;
          if (tx['type'] == AppConstants.txExpense ||
              tx['type'] == AppConstants.txPurchase) {
            totalExpenses += amount;
          }
        }

        // Lifetime general expenses from the expenses table
        final expRes = await supabase
            .from('expenses')
            .select('amount')
            .eq('business_id', businessId);
        for (final exp in expRes as List) {
          totalExpenses += (exp['amount'] as num).toDouble();
        }

        // Counts
        final parties = await supabase
            .from('parties')
            .select('id')
            .eq('business_id', businessId);
        totalParties = (parties as List).length;

        final products = await supabase
            .from('products')
            .select('id')
            .eq('business_id', businessId)
            .eq('is_active', true);
        totalProducts = (products as List).length;
      }

      return PersonalStats(
        fullName: profile?['full_name'] as String? ?? '',
        email: profile?['email'] as String? ??
            supabase.auth.currentUser?.email ??
            '',
        phone: profile?['phone'] as String? ?? '',
        businessName: businessName,
        businessType: businessType,
        subscriptionStatus: subStatus,
        trialDaysLeft: trialDaysLeft,
        totalBusinessSales: totalSales,
        totalBusinessExpenses: totalExpenses,
        totalParties: totalParties,
        totalProducts: totalProducts,
      );
    } catch (_) {
      return const PersonalStats();
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<void> updateName(String newName) async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;
    await supabase
        .from('user_profiles')
        .update({'full_name': newName.trim()})
        .eq('id', userId);
    await refresh();
  }
}

// ── Personal Dashboard Screen ─────────────────────────────────
class PersonalDashboardScreen extends ConsumerWidget {
  const PersonalDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(personalDashboardProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF0F172A)
          : const Color(0xFFF8FAFC),
      body: statsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Colors.purple),
        ),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline,
                  size: 48, color: AppTheme.errorColor),
              const SizedBox(height: 16),
              Text('Failed to load profile',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () =>
                    ref.read(personalDashboardProvider.notifier).refresh(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (stats) => RefreshIndicator(
          color: Colors.purple,
          onRefresh: () => ref.read(personalDashboardProvider.notifier).refresh(),
          child: AnimationLimiter(
            child: CustomScrollView(
              slivers: [
                _PersonalAppBar(stats: stats, ref: ref),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate(
                      AnimationConfiguration.toStaggeredList(
                        duration: const Duration(milliseconds: 450),
                        childAnimationBuilder: (widget) => SlideAnimation(
                          verticalOffset: 50.0,
                          child: FadeInAnimation(child: widget),
                        ),
                        children: [
                          // Business summary header
                          if (stats.businessName.isNotEmpty) ...[
                            Row(
                              children: [
                                Container(
                                  width: 4,
                                  height: 18,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Colors.purple, Colors.blue],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Linked Business',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.5,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Business card
                            _BusinessSummaryCard(stats: stats),
                            const SizedBox(height: 28),

                            // Lifetime stats grid header
                            Row(
                              children: [
                                Container(
                                  width: 4,
                                  height: 18,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Colors.indigo, Colors.purple],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Lifetime Performance',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.5,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _LifetimeStatsGrid(stats: stats),
                            const SizedBox(height: 28),

                            // Subscription card
                            _SubscriptionCard(stats: stats),
                          ] else ...[
                            _NoBusinessCard(),
                          ],

                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── App Bar ──────────────────────────────────────────────────
class _PersonalAppBar extends StatelessWidget {
  final PersonalStats stats;
  final WidgetRef ref;
  const _PersonalAppBar({required this.stats, required this.ref});

  // ── Profile Edit Sheet (tapped from avatar) ─────────────────
  void _showProfileSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProfileEditSheet(stats: stats, ref: ref),
    );
  }

  @override
  Widget build(BuildContext context) {
    final initial = stats.fullName.isNotEmpty
        ? stats.fullName.trim()[0].toUpperCase()
        : '?';

    return SliverAppBar(
      expandedHeight: 160,
      floating: true,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Mesh background layer
            PolyMeshBackground(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF6B21A8).withValues(alpha: 0.85),
                      const Color(0xFF1E3A8A).withValues(alpha: 0.85),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            // Aurora blur visual effect
            Positioned(
              right: -50,
              top: -30,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.pink.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
              ).animate(onPlay: (controller) => controller.repeat(reverse: true))
                  .scale(duration: 4.seconds, begin: const Offset(0.9, 0.9), end: const Offset(1.2, 1.2)),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Tappable glowing gradient profile ring
                        GestureDetector(
                          onTap: () => _showProfileSheet(context),
                          child: Tooltip(
                            message: 'Edit Profile',
                            child: Stack(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(2.5),
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [Colors.pinkAccent, Colors.purpleAccent, Colors.blueAccent],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.purpleAccent,
                                        blurRadius: 12,
                                        spreadRadius: -2,
                                      ),
                                    ],
                                  ),
                                  child: CircleAvatar(
                                    radius: 26,
                                    backgroundColor: Colors.black87,
                                    child: Text(
                                      initial,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 22,
                                          letterSpacing: -0.5),
                                    ),
                                  ),
                                ),
                                // Edit pencil badge
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.black26, width: 0.5),
                                    ),
                                    child: const Icon(Icons.edit_rounded,
                                        size: 10, color: Colors.black87),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                stats.fullName.isEmpty
                                    ? 'My ProfileSpace'
                                    : stats.fullName,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 19,
                                    letterSpacing: -0.4),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                stats.email,
                                style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Tappable Glassmorphic Space Badge
                    GestureDetector(
                      onTap: () => _showProfileSheet(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.manage_accounts_rounded, color: Colors.purple[200], size: 14),
                            const SizedBox(width: 6),
                            const Text(
                              'Personal Space  •  Tap to Edit',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          tooltip: 'Configure Space',
          onPressed: () => context.push(AppRoutes.settings),
          icon: const Icon(Icons.settings_outlined, color: Colors.white),
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}

// ── Profile Card ─────────────────────────────────────────────
class _ProfileCard extends StatefulWidget {
  final PersonalStats stats;
  const _ProfileCard({required this.stats});

  @override
  State<_ProfileCard> createState() => _ProfileCardState();
}

class _ProfileCardState extends State<_ProfileCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        transform: _hovered ? Matrix4.translationValues(0, -3, 0) : Matrix4.identity(),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _hovered 
                ? Colors.purple.withValues(alpha: 0.35)
                : (isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
            width: _hovered ? 1.8 : 1.2,
          ),
          boxShadow: _hovered
              ? [
                  BoxShadow(
                    color: Colors.purple.withValues(alpha: 0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              isDark ? const Color(0xFF1E293B) : Colors.white,
              isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.purple,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Account Details',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _InfoRow(
              icon: Icons.person_rounded,
              iconColor: Colors.purple,
              label: 'Full Name',
              value: widget.stats.fullName.isEmpty ? 'Not set' : widget.stats.fullName,
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Divider(color: Colors.white12, height: 1),
            ),
            _InfoRow(
              icon: Icons.email_rounded,
              iconColor: Colors.blue,
              label: 'Email Address',
              value: widget.stats.email.isEmpty ? 'Not set' : widget.stats.email,
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Divider(color: Colors.white12, height: 1),
            ),
            _InfoRow(
              icon: Icons.phone_rounded,
              iconColor: Colors.teal,
              label: 'Phone Connection',
              value: widget.stats.phone.isEmpty ? 'Not set' : widget.stats.phone,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  const _InfoRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          // Circular backdrop icon wrapper
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.lightTextHint,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Profile Edit Sheet (Personal Space Modal) ─────────────────
class _ProfileEditSheet extends ConsumerStatefulWidget {
  final PersonalStats stats;
  final WidgetRef ref;
  const _ProfileEditSheet({required this.stats, required this.ref});

  @override
  ConsumerState<_ProfileEditSheet> createState() => _ProfileEditSheetState();
}

class _ProfileEditSheetState extends ConsumerState<_ProfileEditSheet> {
  late TextEditingController _nameCtrl;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.stats.fullName);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Name cannot be empty');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.ref
          .read(personalDashboardProvider.notifier)
          .updateName(name);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => _error = 'Failed to save: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final initial = widget.stats.fullName.isNotEmpty
        ? widget.stats.fullName.trim()[0].toUpperCase()
        : '?';

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.06),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 20),

            // Gradient header banner
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  colors: [Color(0xFF6B21A8), Color(0xFF1E3A8A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6B21A8).withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(2.5),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Colors.pinkAccent, Colors.purpleAccent],
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.black87,
                      child: Text(
                        initial,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Personal Space',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          widget.stats.fullName.isEmpty
                              ? 'No Name Set'
                              : widget.stats.fullName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 17,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Editable name field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'DISPLAY NAME',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.lightTextHint,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameCtrl,
                    textCapitalization: TextCapitalization.words,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Enter your full name',
                      prefixIcon: const Icon(Icons.person_rounded,
                          color: Colors.purple, size: 20),
                      errorText: _error,
                      filled: true,
                      fillColor: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.black.withValues(alpha: 0.04),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                            color: Colors.purpleAccent, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                    onChanged: (_) => setState(() => _error = null),
                    onSubmitted: (_) => _save(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Read-only info fields
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.04)
                      : Colors.black.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.07)
                        : Colors.black.withValues(alpha: 0.06),
                  ),
                ),
                child: Column(
                  children: [
                    _ReadOnlyInfoRow(
                      icon: Icons.email_outlined,
                      label: 'Email',
                      value: widget.stats.email.isEmpty
                          ? 'Not linked'
                          : widget.stats.email,
                      iconColor: Colors.blue,
                    ),
                    if (widget.stats.phone.isNotEmpty) ...[
                      const Divider(height: 20),
                      _ReadOnlyInfoRow(
                        icon: Icons.phone_outlined,
                        label: 'Phone',
                        value: widget.stats.phone,
                        iconColor: Colors.teal,
                      ),
                    ],
                    const Divider(height: 20),
                    const Row(
                      children: [
                        Icon(Icons.lock_outline_rounded,
                            size: 14, color: AppTheme.lightTextHint),
                        SizedBox(width: 6),
                        Text(
                          'Email and phone are managed by your account settings',
                          style: TextStyle(
                              fontSize: 10,
                              color: AppTheme.lightTextHint,
                              fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Save button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6B21A8),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_rounded, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'Save Name',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),

            const SizedBox(height: 36),
          ],
        ),
      ),
    );
  }
}

class _ReadOnlyInfoRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _ReadOnlyInfoRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 16, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.lightTextHint,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const Icon(Icons.lock_outline_rounded,
            size: 13, color: AppTheme.lightTextHint),
      ],
    );
  }
}

// ── Business Summary Card (Obsidian Credit Card) ──────────────────
class _BusinessSummaryCard extends StatelessWidget {
  final PersonalStats stats;
  const _BusinessSummaryCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 1.5),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0F172A), // Dark obsidian blue
            Color(0xFF1E1E38), // Premium slate purple
            Color(0xFF3B1E54), // Deep platinum glow leak
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6B21A8).withValues(alpha: 0.22),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Glossy vector light effect
          Positioned(
            left: -40,
            bottom: -50,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFF1C40F).withValues(alpha: 0.08), // Platinum gold shimmer
                    Colors.transparent
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Smart Chip + Wireless Sign
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Card chip
                    Container(
                      width: 40,
                      height: 30,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1C40F).withValues(alpha: 0.75), // Gold smart chip
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.amber[200]!, width: 0.8),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          )
                        ],
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            left: 10,
                            top: 0,
                            bottom: 0,
                            child: Container(width: 1, color: Colors.black26),
                          ),
                          Positioned(
                            right: 10,
                            top: 0,
                            bottom: 0,
                            child: Container(width: 1, color: Colors.black26),
                          ),
                          Positioned(
                            left: 0,
                            right: 0,
                            top: 10,
                            child: Container(height: 1, color: Colors.black26),
                          ),
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 10,
                            child: Container(height: 1, color: Colors.black26),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.contactless_rounded, color: Colors.white60, size: 24),
                  ],
                ),
                
                // Credit Card Number
                Text(
                  '• • • •    • • • •    • • • •    ${stats.businessName.length.toString().padLeft(4, "0")}',
                  style: const TextStyle(
                    fontFamily: 'Courier',
                    color: Colors.white70,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),

                // Cardholder details
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'BUSINESS OWNER CARD',
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            stats.businessName.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'BUSINESS TYPE',
                          style: TextStyle(
                            color: Colors.white38,
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          stats.businessType.toUpperCase(),
                          style: const TextStyle(
                            color: Color(0xFFF1C40F), // Gold platinum highlight
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Lifetime Stats Grid ───────────────────────────────────────
class _LifetimeStatsGrid extends StatelessWidget {
  final PersonalStats stats;
  const _LifetimeStatsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##,##0');
    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = constraints.maxWidth > 600 ? 4 : 2;
        final ratio = constraints.maxWidth > 600 ? 1.6 : 1.35;
        return GridView.count(
          crossAxisCount: cols,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: ratio,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _StatTile(
              label: 'Lifetime Sales',
              value: '${AppConstants.currencySymbol} ${fmt.format(stats.totalBusinessSales)}',
              color: const Color(0xFF10B981),
              icon: Icons.trending_up_rounded,
            ),
            _StatTile(
              label: 'Total Expenses',
              value: '${AppConstants.currencySymbol} ${fmt.format(stats.totalBusinessExpenses)}',
              color: const Color(0xFFEF4444),
              icon: Icons.trending_down_rounded,
            ),
            _StatTile(
              label: 'Client Parties',
              value: '${stats.totalParties}',
              color: const Color(0xFF3B82F6),
              icon: Icons.groups_rounded,
            ),
            _StatTile(
              label: 'Active Inventory',
              value: '${stats.totalProducts}',
              color: const Color(0xFF8B5CF6),
              icon: Icons.widgets_outlined,
            ),
          ],
        );
      },
    ).animate(delay: 200.ms).fadeIn();
  }
}

class _StatTile extends StatefulWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _StatTile({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  State<_StatTile> createState() => _StatTileState();
}

class _StatTileState extends State<_StatTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _hovered 
                ? widget.color.withValues(alpha: 0.3) 
                : (isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
            width: _hovered ? 1.5 : 1.0,
          ),
          boxShadow: _hovered
              ? [
                  BoxShadow(
                    color: widget.color.withValues(alpha: 0.08),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              isDark ? const Color(0xFF1E293B) : Colors.white,
              isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Circular backdrop wrapper for icon
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: widget.color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(widget.icon, color: widget.color, size: 16),
            ),
            const Spacer(),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                widget.value,
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  letterSpacing: -0.3,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              widget.label,
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.lightTextSecondary,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Subscription Card ─────────────────────────────────────────
class _SubscriptionCard extends StatelessWidget {
  final PersonalStats stats;
  const _SubscriptionCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final isTrial = stats.subscriptionStatus == AppConstants.statusTrialActive;
    final isExpired =
        stats.subscriptionStatus == AppConstants.statusTrialExpired ||
            stats.subscriptionStatus == AppConstants.statusExpired;
    final color = isExpired
        ? AppTheme.errorColor
        : isTrial
            ? const Color(0xFF8B5CF6) // Violet status
            : const Color(0xFF10B981); // Emerald check status
    final label = isExpired
        ? 'Subscription Term Expired'
        : isTrial
            ? 'Free Trial Activated${stats.trialDaysLeft != null ? ' — ${stats.trialDaysLeft}d left' : ''}'
            : 'Subscribed Account Active ✓';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark 
            ? const Color(0xFF1E293B) 
            : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.02),
            color.withValues(alpha: 0.08),
          ],
        ),
      ),
      child: Row(
        children: [
          // Glowing subscription status icon
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.25),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Icon(
              isExpired
                  ? Icons.timer_off_rounded
                  : isTrial
                      ? Icons.rocket_launch_rounded
                      : Icons.workspace_premium_rounded,
              color: color,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: color, 
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          if (isExpired || isTrial)
            ElevatedButton(
              onPressed: () => context.push(AppRoutes.subscription),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              child: const Text('Manage'),
            ),
        ],
      ),
    );
  }
}

// ── No Business Card ─────────────────────────────────────────
class _NoBusinessCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder, width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.purple.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.store_rounded, size: 32, color: Colors.purple),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Active Business',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 6),
          const Text(
            'Set up a business workspace to view detailed sales, expenses, and inventory performance charts.',
            style: TextStyle(color: AppTheme.lightTextSecondary, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
