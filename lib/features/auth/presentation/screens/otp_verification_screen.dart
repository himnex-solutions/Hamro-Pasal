import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_saoji/core/router/app_router.dart';
import 'package:smart_saoji/core/theme/app_theme.dart';
import 'package:smart_saoji/core/widgets/app_button.dart';
import 'package:smart_saoji/core/widgets/app_snackbar.dart';
import 'package:smart_saoji/features/auth/presentation/providers/auth_provider.dart';

class OtpVerificationScreen extends ConsumerStatefulWidget {
  final String email;
  const OtpVerificationScreen({super.key, required this.email});

  @override
  ConsumerState<OtpVerificationScreen> createState() =>
      _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen> {
  // 6 individual digit controllers + focus nodes
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _isLoading = false;
  bool _isResending = false;

  // Countdown timer for resend cooldown
  static const _cooldownSeconds = 60;
  int _secondsLeft = _cooldownSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  // ─── Timer ───────────────────────────────────────────────────
  void _startTimer() {
    _timer?.cancel();
    setState(() => _secondsLeft = _cooldownSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        if (_secondsLeft > 0) {
          _secondsLeft--;
        } else {
          t.cancel();
        }
      });
    });
  }

  // ─── OTP helpers ─────────────────────────────────────────────
  String get _otp => _controllers.map((c) => c.text).join();

  void _onDigitChanged(int index, String value) {
    if (value.length > 1) {
      // Handle paste
      final digits = value.replaceAll(RegExp(r'\D'), '');
      for (int i = 0; i < 6 && i < digits.length; i++) {
        _controllers[i].text = digits[i];
      }
      _focusNodes[5].requestFocus();
      return;
    }
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    setState(() {}); // rebuild to enable/disable verify button
  }

  // ─── Verify ──────────────────────────────────────────────────
  Future<void> _verify() async {
    if (_otp.length < 6) {
      AppSnackbar.show(context, 'Please enter the 6-digit code', isError: true);
      return;
    }
    setState(() => _isLoading = true);

    final success = await ref
        .read(authProvider.notifier)
        .verifyOtp(email: widget.email, otp: _otp);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      final authState = ref.read(authProvider);
      if (authState.status == AuthStatus.needsBusinessSetup) {
        context.go(AppRoutes.businessSetup);
      } else {
        context.go(AppRoutes.dashboard);
      }
    } else {
      final error =
          ref.read(authProvider).errorMessage ?? 'Invalid OTP. Try again.';
      AppSnackbar.show(context, error, isError: true);
      // Clear fields on error
      for (final c in _controllers) {
        c.clear();
      }
      _focusNodes[0].requestFocus();
    }
  }

  // ─── Resend ──────────────────────────────────────────────────
  Future<void> _resend() async {
    setState(() => _isResending = true);
    final ok = await ref.read(authProvider.notifier).resendOtp(widget.email);
    if (!mounted) return;
    setState(() => _isResending = false);
    if (ok) {
      AppSnackbar.show(context, 'OTP resent to ${widget.email}',
          isSuccess: true);
      _startTimer();
    } else {
      AppSnackbar.show(context, 'Failed to resend OTP. Try again.',
          isError: true);
    }
  }

  // ─── Build ───────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final canVerify = _otp.length == 6 && !_isLoading;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 450),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Back arrow
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () => context.go(AppRoutes.login),
                      icon: const Icon(Icons.arrow_back_rounded),
                      padding: EdgeInsets.zero,
                    ),
                  ).animate().fadeIn(),

                  const SizedBox(height: 24),

                  // Icon + title
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                AppTheme.primaryColor,
                                AppTheme.primaryLight
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryColor.withValues(alpha: 0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.mark_email_read_rounded,
                              size: 40, color: Colors.white),
                        )
                            .animate()
                            .scale(duration: 600.ms, curve: Curves.elasticOut)
                            .fadeIn(duration: 400.ms),
                        const SizedBox(height: 24),
                        Text(
                          'Verify Your Email',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                          textAlign: TextAlign.center,
                        ).animate(delay: 150.ms).fadeIn().slideY(begin: 0.2),
                        const SizedBox(height: 10),
                        RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: AppTheme.lightTextSecondary),
                            children: [
                              const TextSpan(text: 'We sent a 6-digit code to\n'),
                              TextSpan(
                                text: widget.email,
                                style: const TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ).animate(delay: 200.ms).fadeIn(),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // OTP boxes
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(
                        6,
                        (i) => _OtpBox(
                              controller: _controllers[i],
                              focusNode: _focusNodes[i],
                              onChanged: (v) => _onDigitChanged(i, v),
                            )).animate(delay: 250.ms).fadeIn(),
                  ),

                  const SizedBox(height: 36),

                  // Verify button
                  AppButton(
                    label: 'Verify & Continue',
                    onPressed: canVerify ? _verify : null,
                    isLoading: _isLoading,
                    icon: Icons.verified_rounded,
                  ).animate(delay: 350.ms).fadeIn(),

                  const SizedBox(height: 28),

                  // Resend section
                  Center(
                    child: _secondsLeft > 0
                        ? Text(
                            'Resend code in ${_secondsLeft}s',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: AppTheme.lightTextSecondary),
                          )
                        : _isResending
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : GestureDetector(
                                onTap: _resend,
                                child: RichText(
                                  text: TextSpan(
                                    style: Theme.of(context).textTheme.bodyMedium,
                                    children: const [
                                      TextSpan(text: "Didn't receive it? "),
                                      TextSpan(
                                        text: 'Resend OTP',
                                        style: TextStyle(
                                          color: AppTheme.primaryColor,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                  ).animate(delay: 400.ms).fadeIn(),

                  const SizedBox(height: 32),

                  // Info note
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.infoColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppTheme.infoColor.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline,
                            size: 18, color: AppTheme.infoColor),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'This one-time verification secures your account. '
                            'The code expires in 10 minutes.',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.infoColor,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ).animate(delay: 450.ms).fadeIn(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Single OTP digit box ─────────────────────────────────────
class _OtpBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 56,
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 6, // allows paste of all 6 digits at once
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: onChanged,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppTheme.primaryColor,
            ),
        decoration: InputDecoration(
          counterText: '',
          contentPadding: EdgeInsets.zero,
          filled: true,
          fillColor: controller.text.isNotEmpty
              ? AppTheme.primaryColor.withValues(alpha: 0.08)
              : null,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: controller.text.isNotEmpty
                  ? AppTheme.primaryColor
                  : AppTheme.lightBorder,
              width: controller.text.isNotEmpty ? 2 : 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: AppTheme.primaryColor, width: 2.5),
          ),
        ),
      ),
    );
  }
}
