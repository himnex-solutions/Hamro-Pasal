import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/loading_overlay.dart';
import '../providers/auth_provider.dart';

class EmailOtpScreen extends ConsumerStatefulWidget {
  const EmailOtpScreen({super.key});

  @override
  ConsumerState<EmailOtpScreen> createState() => _EmailOtpScreenState();
}

class _EmailOtpScreenState extends ConsumerState<EmailOtpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  bool _loading = false;
  bool _otpSent = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _loading = true);

    await ref.read(authNotifierProvider.notifier).signInWithOtp(
          email: _emailCtrl.text.trim(),
        );

    if (!mounted) {
      return;
    }
    setState(() => _loading = false);

    final err = ref.read(authNotifierProvider).error;
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(err.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() => _otpSent = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('OTP sent to your email!'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  Future<void> _verifyOtp() async {
    if (_otpCtrl.text.isEmpty) {
      return;
    }
    setState(() => _loading = true);

    await ref.read(authNotifierProvider.notifier).verifyOtp(
          email: _emailCtrl.text.trim(),
          token: _otpCtrl.text.trim(),
        );

    if (!mounted) {
      return;
    }
    setState(() => _loading = false);

    final err = ref.read(authNotifierProvider).error;
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(err.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.error),
      );
      return;
    }

    // GoRouter refreshListenable handles navigation automatically
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: _loading,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Login with OTP'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.go(AppConstants.routeLogin),
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
                      Text('Email Verification ✉️',
                          style: Theme.of(context).textTheme.headlineMedium),
                      const SizedBox(height: 8),
                      Text(
                          _otpSent
                              ? 'Enter the 6-digit code sent to your email'
                              : 'Enter your email to receive a One-Time Password',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: AppColors.textSecondary)),
                      const SizedBox(height: 32),
                      AppTextField(
                        controller: _emailCtrl,
                        label: 'Email',
                        prefixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        enabled: !_otpSent,
                        validator: (v) => v!.isEmpty || !v.contains('@')
                            ? 'Enter valid email'
                            : null,
                      ),
                      if (_otpSent) ...[
                        const SizedBox(height: 16),
                        AppTextField(
                          controller: _otpCtrl,
                          label: 'OTP Code',
                          prefixIcon: Icons.password_rounded,
                          keyboardType: TextInputType.number,
                          validator: (v) =>
                              v!.isEmpty ? 'Enter the code' : null,
                        ),
                      ],
                      const SizedBox(height: 28),
                      AppButton(
                        label: _otpSent ? 'Verify & Login' : 'Send OTP',
                        onPressed: _otpSent ? _verifyOtp : _sendOtp,
                        icon: _otpSent ? Icons.check_circle_outline : Icons.send_rounded,
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
