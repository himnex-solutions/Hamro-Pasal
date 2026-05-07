import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/loading_overlay.dart';
import '../models/business_profile.dart';
import '../models/user_profile.dart';

class BusinessSignupScreen extends ConsumerStatefulWidget {
  const BusinessSignupScreen({super.key});

  @override
  ConsumerState<BusinessSignupScreen> createState() => _BusinessSignupScreenState();
}

class _BusinessSignupScreenState extends ConsumerState<BusinessSignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _businessNameCtrl = TextEditingController();
  final _ownerNameCtrl = TextEditingController();
  final _businessCategoryCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _businessNameCtrl.dispose();
    _ownerNameCtrl.dispose();
    _businessCategoryCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _loading = true);

    try {
      // 1. Create Auth User (no verification email sent)
      final signUpRes = await SupabaseService.instance.signUp(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );

      if (signUpRes.user == null) {
        throw Exception('Failed to create account. Please try again.');
      }

      // 2. Sign in temporarily to save profile data (RLS requires auth)
      await SupabaseService.instance.signInWithPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );

      final userId = Supabase.instance.client.auth.currentUser!.id;

      // 3. Save User Profile (email_verified = false for OTP verification on first login)
      final userProfile = UserProfile(
        id: '',
        userId: userId,
        profileType: 'business',
        fullName: _ownerNameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        isFirstLogin: true,
        emailVerified: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await SupabaseService.instance.upsertUserProfile(userProfile.toJson());

      // 4. Save Business Profile
      final businessProfile = BusinessProfile(
        id: '',
        userId: userId,
        businessName: _businessNameCtrl.text.trim(),
        ownerName: _ownerNameCtrl.text.trim(),
        businessCategory: _businessCategoryCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await SupabaseService.instance.upsertBusinessProfile(businessProfile.toJson());

      // 5. Sign out — user must login manually
      await SupabaseService.instance.signOut();

      if (!mounted) {
        return;
      }
      setState(() => _loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created successfully! Please sign in.'),
          backgroundColor: AppColors.success,
        ),
      );

      // 6. Redirect to login page
      context.go(AppConstants.routeLogin);
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.error),
      );
    }
  }

  // Password Validation
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Minimum 8 characters required';
    }
    if (!RegExp(r'(?=.*[A-Z])').hasMatch(value)) {
      return 'Must contain uppercase letter';
    }
    if (!RegExp(r'(?=.*[a-z])').hasMatch(value)) {
      return 'Must contain lowercase letter';
    }
    if (!RegExp(r'(?=.*[0-9])').hasMatch(value)) {
      return 'Must contain a number';
    }
    if (!RegExp(r'(?=.*[!@#\$&*~])').hasMatch(value)) {
      return 'Must contain a special character';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: _loading,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Business Setup'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.go(AppConstants.routeSelectProfile),
          ),
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Create Business Account 🏢',
                          style: Theme.of(context).textTheme.headlineMedium),
                      const SizedBox(height: 8),
                      Text('Manage your business accounting and inventory',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: AppColors.textSecondary)),
                      const SizedBox(height: 32),

                      AppTextField(
                        controller: _businessNameCtrl,
                        label: 'Business Name',
                        prefixIcon: Icons.storefront_rounded,
                        validator: (v) => v!.isEmpty ? 'Business Name is required' : null,
                      ),
                      const SizedBox(height: 16),

                      AppTextField(
                        controller: _ownerNameCtrl,
                        label: 'Owner Name',
                        prefixIcon: Icons.person_rounded,
                        validator: (v) => v!.isEmpty ? 'Owner Name is required' : null,
                      ),
                      const SizedBox(height: 16),

                      AppTextField(
                        controller: _businessCategoryCtrl,
                        label: 'Business Category',
                        prefixIcon: Icons.category_rounded,
                      ),
                      const SizedBox(height: 16),

                      AppTextField(
                        controller: _emailCtrl,
                        label: 'Email',
                        prefixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) => v!.isEmpty || !v.contains('@')
                            ? 'Enter valid email'
                            : null,
                      ),
                      const SizedBox(height: 16),

                      AppTextField(
                        controller: _phoneCtrl,
                        label: 'Phone Number',
                        prefixIcon: Icons.phone_rounded,
                        keyboardType: TextInputType.phone,
                        validator: (v) => v!.isEmpty ? 'Phone number is required' : null,
                      ),
                      const SizedBox(height: 16),

                      AppTextField(
                        controller: _passCtrl,
                        label: 'Password',
                        prefixIcon: Icons.lock_outline_rounded,
                        obscureText: _obscure,
                        suffixIcon: IconButton(
                          icon: Icon(_obscure
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined),
                          onPressed: () =>
                              setState(() => _obscure = !_obscure),
                        ),
                        validator: _validatePassword,
                      ),
                      const SizedBox(height: 16),

                      AppTextField(
                        controller: _confirmCtrl,
                        label: 'Confirm Password',
                        prefixIcon: Icons.lock_outline_rounded,
                        obscureText: _obscure,
                        validator: (v) => v != _passCtrl.text
                            ? 'Passwords do not match'
                            : null,
                      ),
                      const SizedBox(height: 28),

                      AppButton(
                        label: 'Sign Up',
                        onPressed: _signUp,
                        icon: Icons.app_registration_rounded,
                      ),
                      const SizedBox(height: 24),

                      Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Already have an account? ',
                                style: Theme.of(context).textTheme.bodyMedium),
                            TextButton(
                              onPressed: () =>
                                  context.go(AppConstants.routeLogin),
                              child: const Text('Sign In'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
