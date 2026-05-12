import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hamro_pasal/core/constants/app_constants.dart';
import 'package:hamro_pasal/core/theme/app_theme.dart';
import 'package:hamro_pasal/core/widgets/app_button.dart';
import 'package:hamro_pasal/core/widgets/app_snackbar.dart';
import 'package:hamro_pasal/core/widgets/app_text_field.dart';

class BusinessProfileEditScreen extends ConsumerStatefulWidget {
  const BusinessProfileEditScreen({super.key});

  @override
  ConsumerState<BusinessProfileEditScreen> createState() =>
      _BusinessProfileEditScreenState();
}

class _BusinessProfileEditScreenState
    extends ConsumerState<BusinessProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _panCtrl = TextEditingController();

  String _businessType = AppConstants.businessTypes.first;
  bool _isLoading = false;
  bool _isFetching = true;
  String? _businessId;

  final _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _loadBusiness();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    _panCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadBusiness() async {
    setState(() => _isFetching = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      _businessId = prefs.getString(AppConstants.kSelectedBusinessId);

      if (_businessId == null) {
        // Fallback: fetch from Supabase
        final userId = _supabase.auth.currentUser?.id;
        if (userId != null) {
          final memberRow = await _supabase
              .from('business_members')
              .select('business_id')
              .eq('user_id', userId)
              .limit(1)
              .maybeSingle();
          _businessId = memberRow?['business_id'] as String?;
          if (_businessId != null) {
            await prefs.setString(AppConstants.kSelectedBusinessId, _businessId!);
          }
        }
      }

      if (_businessId == null) {
        if (mounted) {
          AppSnackbar.show(context, 'No business found for your account.', isError: true);
        }
        return;
      }

      final data = await _supabase
          .from('businesses')
          .select()
          .eq('id', _businessId!)
          .maybeSingle();

      if (data != null && mounted) {
        _nameCtrl.text = data['name'] ?? '';
        _phoneCtrl.text = data['phone'] ?? '';
        _emailCtrl.text = data['email'] ?? '';
        _addressCtrl.text = data['address'] ?? '';
        _panCtrl.text = data['pan_number'] ?? '';

        final fetchedType = data['type'] as String?;
        if (fetchedType != null &&
            AppConstants.businessTypes.contains(fetchedType)) {
          _businessType = fetchedType;
        }
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.show(context, 'Failed to load business: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isFetching = false);
    }
  }

  Future<void> _saveBusiness() async {
    if (!_formKey.currentState!.validate()) return;
    if (_businessId == null) {
      AppSnackbar.show(context, 'No business linked to your account.', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _supabase.from('businesses').update({
        'name': _nameCtrl.text.trim(),
        'type': _businessType,
        'phone': _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        'email': _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
        'address':
            _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
        'pan_number':
            _panCtrl.text.trim().isEmpty ? null : _panCtrl.text.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', _businessId!);

      if (mounted) {
        AppSnackbar.show(
            context, '✅ Business profile updated!', isSuccess: true);
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.show(context, 'Update failed: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isFetching
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header banner
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.primaryColor, AppTheme.primaryDark],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withValues(alpha: 0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.store_rounded,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _nameCtrl.text.isEmpty
                                      ? 'Your Business'
                                      : _nameCtrl.text,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                Text(
                                  _businessType,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn().slideY(begin: -0.1, end: 0),

                    const SizedBox(height: 32),

                    // Business Name
                    _label(context, 'Business Name *'),
                    AppTextField(
                      controller: _nameCtrl,
                      hint: 'e.g. Ram General Store',
                      prefixIcon: Icons.store_outlined,
                      textCapitalization: TextCapitalization.words,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Business name is required'
                          : null,
                      onChanged: (_) => setState(() {}),
                    ).animate(delay: 100.ms).fadeIn(),

                    const SizedBox(height: 20),

                    // Business Type
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
                              .map((t) => DropdownMenuItem(
                                    value: t,
                                    child: Text(t),
                                  ))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _businessType = v ?? _businessType),
                        ),
                      ),
                    ).animate(delay: 150.ms).fadeIn(),

                    const SizedBox(height: 20),

                    // Phone
                    _label(context, 'Phone Number'),
                    AppTextField(
                      controller: _phoneCtrl,
                      hint: '98XXXXXXXX',
                      prefixIcon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                    ).animate(delay: 200.ms).fadeIn(),

                    const SizedBox(height: 20),

                    // Email
                    _label(context, 'Business Email'),
                    AppTextField(
                      controller: _emailCtrl,
                      hint: 'business@example.com',
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    ).animate(delay: 250.ms).fadeIn(),

                    const SizedBox(height: 20),

                    // Address
                    _label(context, 'Address'),
                    AppTextField(
                      controller: _addressCtrl,
                      hint: 'Thamel, Kathmandu',
                      maxLines: 2,
                      prefixIcon: Icons.location_on_outlined,
                      textCapitalization: TextCapitalization.sentences,
                    ).animate(delay: 300.ms).fadeIn(),

                    const SizedBox(height: 20),

                    // PAN
                    _label(context, 'PAN Number (Optional)'),
                    AppTextField(
                      controller: _panCtrl,
                      hint: '9-digit PAN number',
                      prefixIcon: Icons.badge_outlined,
                      keyboardType: TextInputType.number,
                    ).animate(delay: 350.ms).fadeIn(),

                    const SizedBox(height: 36),

                    AppButton(
                      label: 'Save Business Profile',
                      onPressed: _saveBusiness,
                      isLoading: _isLoading,
                    ).animate(delay: 400.ms).fadeIn(),

                    const SizedBox(height: 24),
                  ],
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
