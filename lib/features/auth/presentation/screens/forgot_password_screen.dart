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

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() { _emailCtrl.dispose(); super.dispose(); }

  Future<void> _sendReset() async {
    if (_emailCtrl.text.trim().isEmpty) {
      AppSnackbar.show(context, 'Enter your email address', isError: true);
      return;
    }
    setState(() => _isLoading = true);
    final success = await ref.read(authProvider.notifier).sendPasswordReset(_emailCtrl.text.trim());
    if (!mounted) return;
    setState(() { _isLoading = false; _emailSent = success; });
    if (!success) AppSnackbar.show(context, 'Failed to send reset email', isError: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: _emailSent ? _SuccessView() : _FormView(
            emailCtrl: _emailCtrl,
            isLoading: _isLoading,
            onSend: _sendReset,
          ),
        ),
      ),
    );
  }
}

class _FormView extends StatelessWidget {
  final TextEditingController emailCtrl;
  final bool isLoading;
  final VoidCallback onSend;
  const _FormView({required this.emailCtrl, required this.isLoading, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(Icons.lock_reset_outlined, size: 36, color: AppTheme.primaryColor),
        ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
        const SizedBox(height: 24),
        Text('Forgot Password?', style: Theme.of(context).textTheme.headlineSmall)
            .animate(delay: 100.ms).fadeIn(),
        const SizedBox(height: 8),
        Text("Enter your email and we'll send a reset link.",
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.lightTextSecondary))
            .animate(delay: 150.ms).fadeIn(),
        const SizedBox(height: 32),
        AppTextField(
          controller: emailCtrl,
          label: 'Email Address',
          hint: 'you@example.com',
          keyboardType: TextInputType.emailAddress,
          prefixIcon: Icons.email_outlined,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => onSend(),
        ).animate(delay: 200.ms).fadeIn(),
        const SizedBox(height: 24),
        AppButton(label: 'Send Reset Link', onPressed: onSend, isLoading: isLoading,
            icon: Icons.send_outlined).animate(delay: 250.ms).fadeIn(),
      ],
    );
  }
}

class _SuccessView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(color: AppTheme.successColor.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: const Icon(Icons.mark_email_read_outlined, size: 40, color: AppTheme.successColor),
        ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
        const SizedBox(height: 24),
        Text('Email Sent! ✉️', style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center).animate(delay: 200.ms).fadeIn(),
        const SizedBox(height: 12),
        Text('Check your inbox for the password reset link.\nAlso check your spam folder.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.lightTextSecondary),
            textAlign: TextAlign.center).animate(delay: 300.ms).fadeIn(),
        const SizedBox(height: 32),
        AppButton(label: 'Back to Sign In', onPressed: () => context.go(AppRoutes.login),
            outlined: true, icon: Icons.arrow_back).animate(delay: 400.ms).fadeIn(),
      ],
    );
  }
}
