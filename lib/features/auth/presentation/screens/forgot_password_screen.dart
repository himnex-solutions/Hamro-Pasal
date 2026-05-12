import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hamro_pasal/core/router/app_router.dart';
import 'package:hamro_pasal/core/theme/app_theme.dart';
import 'package:hamro_pasal/core/widgets/app_button.dart';
import 'package:hamro_pasal/core/widgets/app_snackbar.dart';
import 'package:hamro_pasal/core/widgets/app_text_field.dart';
import 'package:hamro_pasal/features/auth/presentation/providers/auth_provider.dart';

enum _Stage { email, otp, newPassword }

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  _Stage _stage = _Stage.email;

  // Stage 1
  final _emailCtrl = TextEditingController();

  // Stage 2 — OTP
  final List<TextEditingController> _otpCtrls =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocus = List.generate(6, (_) => FocusNode());
  int _resendCooldown = 0;
  Timer? _cooldownTimer;

  // Stage 3 — New password
  final _pwCtrl = TextEditingController();
  final _confirmPwCtrl = TextEditingController();
  bool _obscurePw = true;
  bool _obscureConfirm = true;

  bool _isLoading = false;
  String _email = '';

  @override
  void dispose() {
    _emailCtrl.dispose();
    for (final c in _otpCtrls) c.dispose();
    for (final f in _otpFocus) f.dispose();
    _pwCtrl.dispose();
    _confirmPwCtrl.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  // ── Stage 1: Send OTP ──────────────────────────────────────
  Future<void> _sendOtp() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      AppSnackbar.show(context, 'Enter a valid email address', isError: true);
      return;
    }
    setState(() => _isLoading = true);
    final ok = await ref
        .read(authProvider.notifier)
        .sendPasswordResetOtp(email);
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (ok) {
      _email = email;
      _startCooldown();
      setState(() => _stage = _Stage.otp);
    } else {
      AppSnackbar.show(context, 'Could not send OTP. Check the email and try again.',
          isError: true);
    }
  }

  // ── Stage 2: Verify OTP ────────────────────────────────────
  String get _otpValue => _otpCtrls.map((c) => c.text).join();

  Future<void> _verifyOtp() async {
    if (_otpValue.length < 6) {
      AppSnackbar.show(context, 'Enter all 6 OTP digits', isError: true);
      return;
    }
    setState(() => _isLoading = true);
    final ok = await ref.read(authProvider.notifier).verifyPasswordResetOtp(
          email: _email,
          otp: _otpValue,
        );
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (ok) {
      setState(() => _stage = _Stage.newPassword);
    } else {
      AppSnackbar.show(context, 'Invalid or expired OTP. Try again.', isError: true);
      // Clear OTP boxes
      for (final c in _otpCtrls) c.clear();
      _otpFocus[0].requestFocus();
    }
  }

  void _startCooldown([int seconds = 60]) {
    setState(() => _resendCooldown = seconds);
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_resendCooldown <= 0) {
        t.cancel();
      } else {
        if (mounted) setState(() => _resendCooldown--);
      }
    });
  }

  Future<void> _resendOtp() async {
    if (_resendCooldown > 0) return;
    setState(() => _isLoading = true);
    await ref.read(authProvider.notifier).sendPasswordResetOtp(_email);
    if (!mounted) return;
    setState(() => _isLoading = false);
    _startCooldown();
    AppSnackbar.show(context, 'OTP resent to $_email');
  }

  // ── Stage 3: Update Password ───────────────────────────────
  Future<void> _updatePassword() async {
    final pw = _pwCtrl.text;
    final confirm = _confirmPwCtrl.text;
    if (pw.length < 6) {
      AppSnackbar.show(context, 'Password must be at least 6 characters', isError: true);
      return;
    }
    if (pw != confirm) {
      AppSnackbar.show(context, 'Passwords do not match', isError: true);
      return;
    }
    setState(() => _isLoading = true);
    final ok = await ref.read(authProvider.notifier).updatePassword(pw);
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (ok) {
      AppSnackbar.show(context, '✅ Password updated! Please sign in.', isSuccess: true);
      context.go(AppRoutes.login);
    } else {
      AppSnackbar.show(context, 'Failed to update password. Try again.', isError: true);
    }
  }

  // ── OTP Box Widget ─────────────────────────────────────────
  Widget _buildOtpBox(int index) {
    return SizedBox(
      width: 46,
      height: 56,
      child: TextField(
        controller: _otpCtrls[index],
        focusNode: _otpFocus[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          counterText: '',
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppTheme.lightBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: AppTheme.primaryColor, width: 2),
          ),
        ),
        onChanged: (val) {
          if (val.isNotEmpty && index < 5) {
            _otpFocus[index + 1].requestFocus();
          } else if (val.isEmpty && index > 0) {
            _otpFocus[index - 1].requestFocus();
          }
          setState(() {});
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_stage == _Stage.email
            ? 'Forgot Password'
            : _stage == _Stage.otp
                ? 'Verify OTP'
                : 'New Password'),
        leading: _stage == _Stage.email
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back_ios_rounded),
                onPressed: () => setState(() {
                  _stage = _stage == _Stage.newPassword
                      ? _Stage.otp
                      : _Stage.email;
                }),
              ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween(
                  begin: const Offset(0.08, 0),
                  end: Offset.zero,
                ).animate(anim),
                child: child,
              ),
            ),
            child: switch (_stage) {
              _Stage.email => _EmailStage(
                  key: const ValueKey('email'),
                  emailCtrl: _emailCtrl,
                  isLoading: _isLoading,
                  onSend: _sendOtp,
                ),
              _Stage.otp => _OtpStage(
                  key: const ValueKey('otp'),
                  email: _email,
                  otpCtrls: _otpCtrls,
                  buildBox: _buildOtpBox,
                  otpValue: _otpValue,
                  isLoading: _isLoading,
                  resendCooldown: _resendCooldown,
                  onVerify: _verifyOtp,
                  onResend: _resendOtp,
                ),
              _Stage.newPassword => _NewPasswordStage(
                  key: const ValueKey('pw'),
                  pwCtrl: _pwCtrl,
                  confirmCtrl: _confirmPwCtrl,
                  obscurePw: _obscurePw,
                  obscureConfirm: _obscureConfirm,
                  isLoading: _isLoading,
                  onTogglePw: () => setState(() => _obscurePw = !_obscurePw),
                  onToggleConfirm: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                  onSave: _updatePassword,
                ),
            },
          ),
        ),
      ),
    );
  }
}

// ── Stage 1: Email Input ───────────────────────────────────────
class _EmailStage extends StatelessWidget {
  final TextEditingController emailCtrl;
  final bool isLoading;
  final VoidCallback onSend;
  const _EmailStage({
    super.key,
    required this.emailCtrl,
    required this.isLoading,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(Icons.lock_reset_outlined,
              size: 36, color: AppTheme.primaryColor),
        ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
        const SizedBox(height: 24),
        Text('Forgot Password?',
                style: Theme.of(context).textTheme.headlineSmall)
            .animate(delay: 100.ms)
            .fadeIn(),
        const SizedBox(height: 8),
        Text(
          "Enter your registered email and we'll send you a 6-digit OTP to reset your password.",
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: AppTheme.lightTextSecondary),
        ).animate(delay: 150.ms).fadeIn(),
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
        AppButton(
          label: 'Send OTP',
          onPressed: onSend,
          isLoading: isLoading,
          icon: Icons.send_outlined,
        ).animate(delay: 250.ms).fadeIn(),
      ],
    );
  }
}

// ── Stage 2: OTP Input ─────────────────────────────────────────
class _OtpStage extends StatelessWidget {
  final String email;
  final List<TextEditingController> otpCtrls;
  final Widget Function(int) buildBox;
  final String otpValue;
  final bool isLoading;
  final int resendCooldown;
  final VoidCallback onVerify;
  final VoidCallback onResend;
  const _OtpStage({
    super.key,
    required this.email,
    required this.otpCtrls,
    required this.buildBox,
    required this.otpValue,
    required this.isLoading,
    required this.resendCooldown,
    required this.onVerify,
    required this.onResend,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(Icons.shield_outlined,
              size: 36, color: AppTheme.primaryColor),
        ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
        const SizedBox(height: 24),
        Text('Enter OTP', style: Theme.of(context).textTheme.headlineSmall)
            .animate(delay: 100.ms)
            .fadeIn(),
        const SizedBox(height: 8),
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
                text: email,
                style: const TextStyle(
                    color: AppTheme.primaryColor, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ).animate(delay: 150.ms).fadeIn(),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(6, (i) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: buildBox(i),
          )),
        ).animate(delay: 200.ms).fadeIn(),
        const SizedBox(height: 32),
        AppButton(
          label: 'Verify OTP',
          onPressed: otpValue.length == 6 ? onVerify : null,
          isLoading: isLoading,
          icon: Icons.verified_outlined,
        ).animate(delay: 250.ms).fadeIn(),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: resendCooldown == 0 ? onResend : null,
          child: Text(
            resendCooldown > 0
                ? 'Resend OTP in ${resendCooldown}s'
                : 'Resend OTP',
            style: TextStyle(
              color: resendCooldown > 0
                  ? AppTheme.lightTextHint
                  : AppTheme.primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ).animate(delay: 300.ms).fadeIn(),
      ],
    );
  }
}

// ── Stage 3: New Password ──────────────────────────────────────
class _NewPasswordStage extends StatelessWidget {
  final TextEditingController pwCtrl;
  final TextEditingController confirmCtrl;
  final bool obscurePw;
  final bool obscureConfirm;
  final bool isLoading;
  final VoidCallback onTogglePw;
  final VoidCallback onToggleConfirm;
  final VoidCallback onSave;
  const _NewPasswordStage({
    super.key,
    required this.pwCtrl,
    required this.confirmCtrl,
    required this.obscurePw,
    required this.obscureConfirm,
    required this.isLoading,
    required this.onTogglePw,
    required this.onToggleConfirm,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppTheme.successColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(Icons.lock_open_outlined,
              size: 36, color: AppTheme.successColor),
        ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
        const SizedBox(height: 24),
        Text('Set New Password',
                style: Theme.of(context).textTheme.headlineSmall)
            .animate(delay: 100.ms)
            .fadeIn(),
        const SizedBox(height: 8),
        Text(
          'OTP verified! Create a strong new password for your account.',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: AppTheme.lightTextSecondary),
        ).animate(delay: 150.ms).fadeIn(),
        const SizedBox(height: 32),
        AppTextField(
          controller: pwCtrl,
          label: 'New Password',
          hint: '••••••••',
          obscureText: obscurePw,
          prefixIcon: Icons.lock_outline,
          textInputAction: TextInputAction.next,
          suffixIcon: IconButton(
            onPressed: onTogglePw,
            icon: Icon(obscurePw
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined),
          ),
        ).animate(delay: 200.ms).fadeIn(),
        const SizedBox(height: 16),
        AppTextField(
          controller: confirmCtrl,
          label: 'Confirm Password',
          hint: '••••••••',
          obscureText: obscureConfirm,
          prefixIcon: Icons.lock_outline,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => onSave(),
          suffixIcon: IconButton(
            onPressed: onToggleConfirm,
            icon: Icon(obscureConfirm
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined),
          ),
        ).animate(delay: 250.ms).fadeIn(),
        const SizedBox(height: 8),
        // Password rules hint
        Text(
          '• At least 6 characters\n• Passwords must match',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: AppTheme.lightTextHint),
        ).animate(delay: 280.ms).fadeIn(),
        const SizedBox(height: 24),
        AppButton(
          label: 'Update Password',
          onPressed: onSave,
          isLoading: isLoading,
          icon: Icons.save_outlined,
        ).animate(delay: 300.ms).fadeIn(),
      ],
    );
  }
}
