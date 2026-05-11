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

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final success = await ref.read(authProvider.notifier).signIn(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
        );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      final authState = ref.read(authProvider);
      switch (authState.status) {
        case AuthStatus.needsOtpVerification:
          // First-time login → go to OTP verification screen
          context.push(
            AppRoutes.otpVerification,
            extra: authState.pendingEmail ?? _emailCtrl.text.trim(),
          );
          break;
        case AuthStatus.needsBusinessSetup:
          context.go(AppRoutes.businessSetup);
          break;
        case AuthStatus.authenticated:
          context.go(AppRoutes.dashboard);
          break;
        default:
          break;
      }
    } else {
      final error = ref.read(authProvider).errorMessage ?? 'Login failed';
      AppSnackbar.show(context, error, isError: true);
    }
  }

  Future<void> _googleLogin() async {
    setState(() => _isLoading = true);
    final success = await ref.read(authProvider.notifier).signInWithGoogle();
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (success) {
      final authState = ref.read(authProvider);
      if (authState.status == AuthStatus.needsBusinessSetup) {
        context.go(AppRoutes.businessSetup);
      } else {
        context.go(AppRoutes.dashboard);
      }
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
                const SizedBox(height: 32),

                // Brand header
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.store_rounded,
                          color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Hamro Pasal',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ],
                ).animate().fadeIn().slideX(begin: -0.1, end: 0),

                const SizedBox(height: 40),

                Text('Welcome Back 👋',
                        style: Theme.of(context).textTheme.headlineMedium)
                    .animate(delay: 100.ms)
                    .fadeIn()
                    .slideY(begin: 0.2, end: 0),

                const SizedBox(height: 8),

                Text(
                  'Sign in to continue managing your business.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.lightTextSecondary,
                      ),
                ).animate(delay: 150.ms).fadeIn(),

                const SizedBox(height: 32),

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
                  hint: '••••••••',
                  obscureText: _obscurePassword,
                  prefixIcon: Icons.lock_outline,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _login(),
                  suffixIcon: IconButton(
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                    icon: Icon(_obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Password is required';
                    if (v.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ).animate(delay: 250.ms).fadeIn(),

                const SizedBox(height: 12),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => context.push(AppRoutes.forgotPassword),
                    child: const Text('Forgot Password?'),
                  ),
                ).animate(delay: 300.ms).fadeIn(),

                const SizedBox(height: 8),

                AppButton(
                  label: 'Sign In',
                  onPressed: _login,
                  isLoading: _isLoading,
                  icon: Icons.login_rounded,
                ).animate(delay: 350.ms).fadeIn(),

                const SizedBox(height: 20),

                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('OR',
                          style: Theme.of(context).textTheme.bodySmall),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ).animate(delay: 400.ms).fadeIn(),

                const SizedBox(height: 16),

                OutlinedButton.icon(
                  onPressed: _isLoading ? null : _googleLogin,
                  icon: const Icon(Icons.g_mobiledata_rounded, size: 24),
                  label: const Text('Continue with Google'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ).animate(delay: 450.ms).fadeIn(),

                const SizedBox(height: 32),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Don't have an account? ",
                        style: Theme.of(context).textTheme.bodyMedium),
                    GestureDetector(
                      onTap: () => context.push(AppRoutes.signup),
                      child: Text(
                        'Sign Up',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                  ],
                ).animate(delay: 500.ms).fadeIn(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
