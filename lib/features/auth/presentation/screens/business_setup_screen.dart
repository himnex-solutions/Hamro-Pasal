import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hamro_pasal/core/constants/app_constants.dart';
import 'package:hamro_pasal/core/router/app_router.dart';
import 'package:hamro_pasal/core/theme/app_theme.dart';
import 'package:hamro_pasal/core/widgets/app_button.dart';
import 'package:hamro_pasal/core/widgets/app_snackbar.dart';
import 'package:hamro_pasal/core/widgets/app_text_field.dart';
import 'package:hamro_pasal/features/auth/presentation/providers/auth_provider.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class BusinessSetupScreen extends ConsumerStatefulWidget {
  const BusinessSetupScreen({super.key});

  @override
  ConsumerState<BusinessSetupScreen> createState() =>
      _BusinessSetupScreenState();
}

class _BusinessSetupScreenState extends ConsumerState<BusinessSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _panCtrl = TextEditingController();
  String _businessType = AppConstants.businessTypes.first;
  bool _isLoading = false;
  bool _loadingProfile = true;

  @override
  void initState() {
    super.initState();
    _loadUserPhone();
  }

  /// Fetches the signed-in user's phone from user_profiles and pre-fills
  /// the business phone field. The field is then rendered as read-only.
  Future<void> _loadUserPhone() async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final profile = await supabase
          .from('user_profiles')
          .select('phone')
          .eq('id', userId)
          .maybeSingle();

      final phone = profile?['phone'] as String? ?? '';
      if (phone.isNotEmpty) {
        _phoneCtrl.text = phone;
      }
    } catch (_) {
      // Non-fatal: user can still proceed without phone auto-fill
    } finally {
      if (mounted) setState(() => _loadingProfile = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _panCtrl.dispose();
    super.dispose();
  }

  Future<void> _createBusiness() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser!.id;

      // ── PAN uniqueness check ──────────────────────────────────────
      final pan = _panCtrl.text.trim();
      if (pan.isNotEmpty) {
        final panTaken =
            await ref.read(authProvider.notifier).isPanTaken(pan);
        if (panTaken) {
          if (mounted) {
            AppSnackbar.show(
              context,
              'This PAN number is already registered by another business.',
              isError: true,
            );
          }
          return;
        }
      }

      final businessId = const Uuid().v4();
      final now = DateTime.now().toIso8601String();
      final trialEnd =
          DateTime.now().add(const Duration(days: AppConstants.trialDays));

      // Create business
      await supabase.from('businesses').insert({
        'id': businessId,
        'owner_id': userId,
        'name': _nameCtrl.text.trim(),
        'type': _businessType,
        'phone': _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        'address':
            _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
        'pan_number': pan.isEmpty ? null : pan,
        'currency': AppConstants.currency,
        'created_at': now,
        'updated_at': now,
      });

      // Save business ID locally for all providers
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.kSelectedBusinessId, businessId);

      // Add owner as business member
      await supabase.from('business_members').insert({
        'id': const Uuid().v4(),
        'business_id': businessId,
        'user_id': userId,
        'role': AppConstants.roleOwner,
        'is_active': true,
        'joined_at': now,
      });

      // Create subscription with 14-day trial
      await supabase.from('subscriptions').insert({
        'id': const Uuid().v4(),
        'business_id': businessId,
        'status': AppConstants.statusTrialActive,
        'trial_start_date': now,
        'trial_end_date': trialEnd.toIso8601String(),
        'is_trial_used': true,
        'created_at': now,
        'updated_at': now,
      });

      // Create default cash account
      await supabase.from('bank_accounts').insert({
        'id': const Uuid().v4(),
        'business_id': businessId,
        'name': 'Main Cash',
        'type': 'cash',
        'balance': 0,
        'created_at': now,
        'updated_at': now,
      });

      if (mounted) {
        AppSnackbar.show(context, 'Business created! 14-day trial started.',
            isSuccess: true);
        context.go(AppRoutes.dashboard);
      }
    } catch (e) {
      if (mounted) AppSnackbar.show(context, e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),

                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primaryColor, AppTheme.primaryDark],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.store_rounded,
                          color: Colors.white, size: 32),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Setup Your Business',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(color: Colors.white)),
                            Text('14-day free trial starts now!',
                                style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn().slideY(begin: -0.1, end: 0),

                const SizedBox(height: 32),

                _label(context, 'Business Name *'),
                AppTextField(
                  controller: _nameCtrl,
                  hint: 'e.g. Ram General Store',
                  prefixIcon: Icons.store_outlined,
                  textCapitalization: TextCapitalization.words,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Business name is required'
                      : null,
                ).animate(delay: 100.ms).fadeIn(),

                const SizedBox(height: 16),

                _label(context, 'Business Type'),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.lightBorder),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _businessType,
                      isExpanded: true,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      borderRadius: BorderRadius.circular(12),
                      items: AppConstants.businessTypes
                          .map(
                              (t) => DropdownMenuItem(value: t, child: Text(t)))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _businessType = v ?? _businessType),
                    ),
                  ),
                ).animate(delay: 150.ms).fadeIn(),

                const SizedBox(height: 16),

                // ── Business Phone (auto-filled from user profile, read-only) ──
                _label(context, 'Business Phone Number'),
                if (_loadingProfile)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  )
                else
                  Stack(
                    children: [
                      AppTextField(
                        controller: _phoneCtrl,
                        hint: '98XXXXXXXX',
                        keyboardType: TextInputType.phone,
                        prefixIcon: Icons.phone_outlined,
                        // Read-only: phone is always the owner's registered phone
                        readOnly: true,
                      ),
                      // Lock badge overlay
                      Positioned(
                        right: 12,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: Tooltip(
                            message: 'Automatically filled from your account',
                            child: Icon(
                              Icons.lock_outline_rounded,
                              size: 18,
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ).animate(delay: 200.ms).fadeIn(),

                // Info chip below phone field
                if (!_loadingProfile)
                  Padding(
                    padding: const EdgeInsets.only(top: 6, left: 4, bottom: 4),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline,
                            size: 13,
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.7)),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'Phone number is linked to your account and cannot be changed here.',
                            style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 16),

                _label(context, 'Address'),
                AppTextField(
                  controller: _addressCtrl,
                  hint: 'Thamel, Kathmandu',
                  maxLines: 2,
                  prefixIcon: Icons.location_on_outlined,
                  textCapitalization: TextCapitalization.sentences,
                ).animate(delay: 250.ms).fadeIn(),

                const SizedBox(height: 16),

                _label(context, 'PAN Number (Optional)'),
                AppTextField(
                  controller: _panCtrl,
                  hint: '9-digit PAN number',
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.badge_outlined,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return null; // optional
                    final digits =
                        v.trim().replaceAll(RegExp(r'[^0-9]'), '');
                    if (digits.length != 9) {
                      return 'PAN number must be exactly 9 digits';
                    }
                    return null;
                  },
                ).animate(delay: 300.ms).fadeIn(),

                const SizedBox(height: 32),

                // Trial info
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.accentColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppTheme.accentColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.rocket_launch_outlined,
                          color: AppTheme.accentDark, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Your 14-day free trial includes all features. No payment required.',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AppTheme.accentDark),
                        ),
                      ),
                    ],
                  ),
                ).animate(delay: 350.ms).fadeIn(),

                const SizedBox(height: 24),

                AppButton(
                  label: 'Start My Free Trial',
                  icon: Icons.rocket_launch_outlined,
                  onPressed: _createBusiness,
                  isLoading: _isLoading,
                ).animate(delay: 400.ms).fadeIn(),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}
