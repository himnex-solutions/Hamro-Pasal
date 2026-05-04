import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/loading_overlay.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    await ref.read(authNotifierProvider.notifier).signIn(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text,
        );
    if (!mounted) return;
    setState(() => _loading = false);
    final err = ref.read(authNotifierProvider).error;
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    // GoRouter's refreshListenable automatically redirects to dashboard
    // after login succeeds. No manual context.go() needed here.
  }

  Future<void> _googleSignIn() async {
    setState(() => _loading = true);
    await ref.read(authNotifierProvider.notifier).signInWithGoogle();
    if (!mounted) return;
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 600;

    return LoadingOverlay(
      isLoading: _loading,
      child: Scaffold(
        body: Row(
          children: [
            // Left branding panel (wide screens only)
            if (isWide)
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, Color(0xFF0D2F8A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: const Icon(Icons.storefront_rounded,
                            size: 60, color: Colors.white),
                      ),
                      const SizedBox(height: 24),
                      Text(AppConstants.appName,
                          style: Theme.of(context)
                              .textTheme
                              .displaySmall
                              ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Text(AppConstants.appTagline,
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(
                                  color: Colors.white.withOpacity(0.7))),
                    ],
                  ),
                ),
              ),

            // Form panel
            Expanded(
              child: SafeArea(
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
                            if (!isWide) ...[
                              const Icon(Icons.storefront_rounded,
                                  size: 48, color: AppColors.primary),
                              const SizedBox(height: 16),
                            ],
                            Text('Welcome Back! 👋',
                                style:
                                    Theme.of(context).textTheme.headlineMedium),
                            const SizedBox(height: 8),
                            Text('Sign in to manage your shop',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: AppColors.textSecondary)),
                            const SizedBox(height: 36),

                            AppTextField(
                              controller: _emailCtrl,
                              label: 'Email',
                              hint: 'your@email.com',
                              prefixIcon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              validator: (v) => v!.isEmpty || !v.contains('@')
                                  ? 'Enter valid email'
                                  : null,
                            ),
                            const SizedBox(height: 16),

                            AppTextField(
                              controller: _passCtrl,
                              label: 'Password',
                              hint: '••••••••',
                              prefixIcon: Icons.lock_outline_rounded,
                              obscureText: _obscure,
                              suffixIcon: IconButton(
                                icon: Icon(_obscure
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined),
                                onPressed: () =>
                                    setState(() => _obscure = !_obscure),
                              ),
                              validator: (v) =>
                                  v!.length < 6 ? 'Min 6 characters' : null,
                            ),
                            const SizedBox(height: 8),

                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {},
                                child: const Text('Forgot Password?'),
                              ),
                            ),
                            const SizedBox(height: 16),

                            AppButton(
                              label: 'Sign In',
                              onPressed: _signIn,
                              icon: Icons.login_rounded,
                            ),
                            const SizedBox(height: 16),

                            Row(children: [
                              const Expanded(child: Divider()),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                child: Text('or',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                            color: AppColors.textSecondary)),
                              ),
                              const Expanded(child: Divider()),
                            ]),
                            const SizedBox(height: 16),

                            // Google Sign In
                            OutlinedButton.icon(
                              onPressed: _googleSignIn,
                              icon: const Icon(Icons.g_mobiledata_rounded,
                                  size: 24),
                              label: const Text('Continue with Google'),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 52),
                              ),
                            ),
                            const SizedBox(height: 28),

                            Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text("Don't have an account? ",
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium),
                                  TextButton(
                                    onPressed: () =>
                                        context.go(AppConstants.routeSignup),
                                    child: const Text('Sign Up'),
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
          ],
        ),
      ),
    );
  }
}
