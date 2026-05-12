import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hamro_pasal/core/theme/app_theme.dart';
import 'package:hamro_pasal/core/widgets/app_button.dart';
import 'package:hamro_pasal/core/widgets/app_snackbar.dart';
import 'package:hamro_pasal/core/widgets/app_text_field.dart';

class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  bool _isLoading = false;
  bool _isFetching = true;
  String _email = '';

  final _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _isFetching = true);
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final data = await _supabase
          .from('user_profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (data != null && mounted) {
        _nameCtrl.text = data['full_name'] ?? '';
        _phoneCtrl.text = data['phone'] ?? '';
        _email = data['email'] ?? _supabase.auth.currentUser?.email ?? '';
      }
    } catch (e) {
      if (mounted) AppSnackbar.show(context, 'Failed to load profile: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isFetching = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      await _supabase.from('user_profiles').upsert({
        'id': userId,
        'full_name': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        'email': _email,
        'updated_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        AppSnackbar.show(context, '✅ Profile updated successfully!', isSuccess: true);
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) AppSnackbar.show(context, 'Update failed: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
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
                    // Avatar section
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppTheme.primaryColor, AppTheme.primaryDark],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryColor.withValues(alpha: 0.35),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                _nameCtrl.text.isNotEmpty
                                    ? _nameCtrl.text.trim()[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _email,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.lightTextSecondary,
                                ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9)),

                    const SizedBox(height: 36),

                    // Email (read-only)
                    _sectionLabel(context, 'Email Address'),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.lightBorder),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.email_outlined, color: AppTheme.lightTextHint, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _email.isEmpty ? 'No email' : _email,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.lightTextSecondary,
                                  ),
                            ),
                          ),
                          const Icon(Icons.lock_outline, color: AppTheme.lightTextHint, size: 16),
                        ],
                      ),
                    ).animate(delay: 100.ms).fadeIn(),

                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Text(
                        'Email cannot be changed here.',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppTheme.lightTextHint,
                            ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    _sectionLabel(context, 'Full Name *'),
                    AppTextField(
                      controller: _nameCtrl,
                      hint: 'Your full name',
                      prefixIcon: Icons.person_outline,
                      textCapitalization: TextCapitalization.words,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                      onChanged: (_) => setState(() {}), // refresh avatar initial
                    ).animate(delay: 150.ms).fadeIn(),

                    const SizedBox(height: 20),

                    _sectionLabel(context, 'Phone Number'),
                    AppTextField(
                      controller: _phoneCtrl,
                      hint: '98XXXXXXXX',
                      prefixIcon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                    ).animate(delay: 200.ms).fadeIn(),

                    const SizedBox(height: 36),

                    AppButton(
                      label: 'Save Changes',
                      onPressed: _saveProfile,
                      isLoading: _isLoading,
                    ).animate(delay: 250.ms).fadeIn(),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _sectionLabel(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}
