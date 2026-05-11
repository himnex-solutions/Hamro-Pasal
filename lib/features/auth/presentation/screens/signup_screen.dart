import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hamro_pasal/core/router/app_router.dart';
import 'package:hamro_pasal/core/theme/app_theme.dart';
import 'package:hamro_pasal/core/widgets/app_button.dart';
import 'package:hamro_pasal/core/widgets/app_snackbar.dart';
import 'package:hamro_pasal/core/widgets/app_text_field.dart';
import 'package:hamro_pasal/features/auth/presentation/providers/auth_provider.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameCtrl.dispose(); _emailCtrl.dispose();
    _passwordCtrl.dispose(); _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final success = await ref.read(authProvider.notifier).signUp(
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
      fullName: _nameCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (success) {
      AppSnackbar.show(
        context,
        '✅ Account created! Please sign in to continue.',
        isSuccess: true,
        duration: const Duration(seconds: 4),
      );
      context.go(AppRoutes.login);
    } else {
      final error = ref.read(authProvider).errorMessage ?? 'Registration failed';
      AppSnackbar.show(context, error, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account'), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Join Hamro Pasal 🚀',
                  style: Theme.of(context).textTheme.headlineMedium)
                  .animate().fadeIn(),
              const SizedBox(height: 8),
              Text('Start your 14-day free trial. No credit card required.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.lightTextSecondary))
                  .animate(delay: 50.ms).fadeIn(),

              const SizedBox(height: 8),

              // Trial badge
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.accentColor, AppTheme.accentDark],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.rocket_launch_outlined, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text('14 days FREE — No credit card needed',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                  ],
                ),
              ).animate(delay: 100.ms).fadeIn().scale(begin: const Offset(0.9, 0.9)),

              const SizedBox(height: 24),

              AppTextField(
                controller: _nameCtrl,
                label: 'Full Name',
                hint: 'Ram Bahadur Shrestha',
                prefixIcon: Icons.person_outline,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
              ).animate(delay: 150.ms).fadeIn(),

              const SizedBox(height: 16),

              AppTextField(
                controller: _emailCtrl,
                label: 'Email Address',
                hint: 'you@example.com',
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.email_outlined,
                textInputAction: TextInputAction.next,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Email is required';
                  if (!v.contains('@')) return 'Enter a valid email';
                  return null;
                },
              ).animate(delay: 200.ms).fadeIn(),

              const SizedBox(height: 16),

              AppTextField(
                controller: _passwordCtrl,
                label: 'Password',
                hint: 'Min. 6 characters',
                obscureText: _obscurePassword,
                prefixIcon: Icons.lock_outline,
                textInputAction: TextInputAction.next,
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Password is required';
                  if (v.length < 6) return 'Minimum 6 characters';
                  return null;
                },
              ).animate(delay: 250.ms).fadeIn(),

              const SizedBox(height: 16),

              AppTextField(
                controller: _confirmCtrl,
                label: 'Confirm Password',
                hint: '••••••••',
                obscureText: _obscureConfirm,
                prefixIcon: Icons.lock_outline,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _signup(),
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  icon: Icon(_obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Please confirm password';
                  if (v != _passwordCtrl.text) return 'Passwords do not match';
                  return null;
                },
              ).animate(delay: 300.ms).fadeIn(),

              const SizedBox(height: 32),

              AppButton(
                label: 'Create Account & Start Trial',
                onPressed: _signup,
                isLoading: _isLoading,
                icon: Icons.rocket_launch_outlined,
              ).animate(delay: 350.ms).fadeIn(),

              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Already have an account? ', style: Theme.of(context).textTheme.bodyMedium),
                  GestureDetector(
                    onTap: () => context.go(AppRoutes.login),
                    child: Text('Sign In',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.primaryColor, fontWeight: FontWeight.w700)),
                  ),
                ],
              ).animate(delay: 400.ms).fadeIn(),

              const SizedBox(height: 20),

              Text(
                'By creating an account, you agree to our Terms of Service and Privacy Policy.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.lightTextHint),
                textAlign: TextAlign.center,
              ).animate(delay: 450.ms).fadeIn(),
            ],
          ),
        ),
      ),
    );
  }
}
