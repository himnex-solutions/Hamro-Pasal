import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hamro_pasal/core/router/app_router.dart';
import 'package:hamro_pasal/core/widgets/app_snackbar.dart';
import 'package:hamro_pasal/core/widgets/wavy_divider.dart';
import 'package:hamro_pasal/features/auth/presentation/providers/auth_provider.dart';

enum _Stage { email, otp, newPassword }

// ── Color tokens ─────────────────────────────────────────────
const _gradientStart = Color(0xFF1E2ED2); // royal blue
const _gradientEnd = Color(0xFF6B58F5); // light purple/blue
const _dark = Color(0xFF0F172A); // slate-black for titles
const _grey = Color(0xFF94A3B8); // slate-grey for subtitle
const _border = Color(0xFFE2E8F0); // border color

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
    for (final c in _otpCtrls) {
      c.dispose();
    }
    for (final f in _otpFocus) {
      f.dispose();
    }
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
    final ok =
        await ref.read(authProvider.notifier).sendPasswordResetOtp(email);
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (ok) {
      _email = email;
      _startCooldown();
      setState(() => _stage = _Stage.otp);
    } else {
      AppSnackbar.show(
          context, 'Could not send OTP. Check the email and try again.',
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
      AppSnackbar.show(context, 'Invalid or expired OTP. Try again.',
          isError: true);
      // Clear OTP boxes
      for (final c in _otpCtrls) {
        c.clear();
      }
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
      AppSnackbar.show(context, 'Password must be at least 6 characters',
          isError: true);
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
      AppSnackbar.show(context, '✅ Password updated! Please sign in.',
          isSuccess: true);
      context.go(AppRoutes.login);
    } else {
      AppSnackbar.show(context, 'Failed to update password. Try again.',
          isError: true);
    }
  }

  // ── OTP Box Widget ─────────────────────────────────────────
  Widget _buildOtpBox(int index) {
    return SizedBox(
      width: 44,
      height: 56,
      child: TextField(
        controller: _otpCtrls[index],
        focusNode: _otpFocus[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: _dark,
        ),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          counterText: '',
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _border, width: 1.2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _border, width: 1.2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF2C3BD5), width: 1.8),
          ),
          filled: true,
          fillColor: Colors.white,
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
    final size = MediaQuery.of(context).size;
    final topSectionHeight = size.height * 0.28;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ── Top Gradient Section ──────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: topSectionHeight,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [_gradientStart, _gradientEnd],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),

          // ── Safe Area Controls (Back Button & Title) ──────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Back button
                    GestureDetector(
                      onTap: () {
                        if (_stage == _Stage.email) {
                          context.go(AppRoutes.login);
                        } else {
                          setState(() {
                            _stage = _stage == _Stage.newPassword
                                ? _Stage.otp
                                : _Stage.email;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                    const Text(
                      'Reset Password',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 44), // balance back button space
                  ],
                ),
              ),
            ),
          ),

          // ── White Bottom Sheet Card with Wavy Divider ─────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            top: topSectionHeight - 45, // slight overlap to display waves beautifully
            child: WavyDivider(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(left: 24, right: 24, top: 60, bottom: 32),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.08, 0),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: anim,
                        curve: Curves.easeOutCubic,
                      )),
                      child: child,
                    ),
                  ),
                  child: switch (_stage) {
                    _Stage.email => _buildEmailStage(),
                    _Stage.otp => _buildOtpStage(),
                    _Stage.newPassword => _buildNewPasswordStage(),
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Stage 1: Email Input ─────────────────────────────────────
  Widget _buildEmailStage() {
    return Column(
      key: const ValueKey('email_stage'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFF2C3BD5).withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lock_reset_rounded,
              size: 38,
              color: Color(0xFF2C3BD5),
            ),
          ),
        ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),

        const SizedBox(height: 24),

        const Text(
          'Forgot Password?',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: _dark,
            letterSpacing: -0.3,
          ),
        ),

        const SizedBox(height: 8),

        const Text(
          "Enter your registered email and we'll send you a 6-digit OTP code to reset your password.",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14.5,
            color: _grey,
            height: 1.5,
            fontWeight: FontWeight.w500,
          ),
        ),

        const SizedBox(height: 32),

        _CustomAuthField(
          controller: _emailCtrl,
          label: 'Email Address',
          icon: Icons.mail_outline_rounded,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _sendOtp(),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Email is required';
            if (!v.contains('@')) return 'Enter a valid email';
            return null;
          },
        ),

        const SizedBox(height: 28),

        _GradientButton(
          label: 'Send OTP',
          isLoading: _isLoading,
          onPressed: _sendOtp,
        ),
      ],
    );
  }

  // ── Stage 2: OTP Verify ──────────────────────────────────────
  Widget _buildOtpStage() {
    return Column(
      key: const ValueKey('otp_stage'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFF2C3BD5).withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shield_outlined,
              size: 38,
              color: Color(0xFF2C3BD5),
            ),
          ),
        ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),

        const SizedBox(height: 24),

        const Text(
          'Enter OTP Code',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: _dark,
            letterSpacing: -0.3,
          ),
        ),

        const SizedBox(height: 8),

        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: const TextStyle(
              fontSize: 14.5,
              color: _grey,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
            children: [
              const TextSpan(text: 'We sent a 6-digit code to\n'),
              TextSpan(
                text: _email,
                style: const TextStyle(
                  color: Color(0xFF2C3BD5),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // OTP inputs
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            6,
            (i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _buildOtpBox(i),
            ),
          ),
        ),

        const SizedBox(height: 32),

        _GradientButton(
          label: 'Verify OTP',
          isLoading: _isLoading,
          onPressed: _otpValue.length == 6 ? _verifyOtp : null,
        ),

        const SizedBox(height: 24),

        Center(
          child: GestureDetector(
            onTap: _resendCooldown == 0 ? _resendOtp : null,
            child: Text(
              _resendCooldown > 0
                  ? 'Resend OTP in ${_resendCooldown}s'
                  : 'Resend OTP',
              style: TextStyle(
                color: _resendCooldown > 0
                    ? _grey
                    : const Color(0xFF2C3BD5),
                fontWeight: FontWeight.w700,
                fontSize: 14.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Stage 3: New Password ────────────────────────────────────
  Widget _buildNewPasswordStage() {
    return Column(
      key: const ValueKey('pw_stage'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lock_open_rounded,
              size: 38,
              color: Colors.green,
            ),
          ),
        ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),

        const SizedBox(height: 24),

        const Text(
          'Reset Password',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: _dark,
            letterSpacing: -0.3,
          ),
        ),

        const SizedBox(height: 8),

        const Text(
          'OTP verified successfully. Create a strong new password for your account.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14.5,
            color: _grey,
            height: 1.5,
            fontWeight: FontWeight.w500,
          ),
        ),

        const SizedBox(height: 32),

        _CustomAuthField(
          controller: _pwCtrl,
          label: 'New Password',
          icon: Icons.lock_outline_rounded,
          obscureText: _obscurePw,
          textInputAction: TextInputAction.next,
          suffix: GestureDetector(
            onTap: () => setState(() => _obscurePw = !_obscurePw),
            child: Icon(
              _obscurePw
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              size: 20,
              color: _grey,
            ),
          ),
        ),

        const SizedBox(height: 16),

        _CustomAuthField(
          controller: _confirmPwCtrl,
          label: 'Confirm Password',
          icon: Icons.lock_outline_rounded,
          obscureText: _obscureConfirm,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _updatePassword(),
          suffix: GestureDetector(
            onTap: () => setState(() => _obscureConfirm = !_obscureConfirm),
            child: Icon(
              _obscureConfirm
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              size: 20,
              color: _grey,
            ),
          ),
        ),

        const SizedBox(height: 12),

        const Padding(
          padding: EdgeInsets.only(left: 4),
          child: Text(
            '• At least 6 characters\n• Passwords must match exactly',
            style: TextStyle(
              fontSize: 12.5,
              color: _grey,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        const SizedBox(height: 28),

        _GradientButton(
          label: 'Update Password',
          isLoading: _isLoading,
          onPressed: _updatePassword,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Custom Auth Text Field (animated floating label + icon design)
// ─────────────────────────────────────────────────────────────

class _CustomAuthField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final IconData? icon;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final void Function(String)? onSubmitted;
  final Widget? suffix;

  const _CustomAuthField({
    required this.controller,
    required this.label,
    this.icon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction,
    this.validator,
    this.onSubmitted,
    this.suffix,
  });

  @override
  State<_CustomAuthField> createState() => _CustomAuthFieldState();
}

class _CustomAuthFieldState extends State<_CustomAuthField> {
  late FocusNode _internalFocus;
  bool _isFocused = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _internalFocus = FocusNode();
    _internalFocus.addListener(_onFocusChange);
    widget.controller.addListener(_onTextChanged);
  }

  void _onFocusChange() {
    if (mounted) {
      setState(() {
        _isFocused = _internalFocus.hasFocus;
      });
    }
  }

  void _onTextChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _internalFocus.removeListener(_onFocusChange);
    widget.controller.removeListener(_onTextChanged);
    _internalFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasError = _errorText != null;
    final isFloated = widget.controller.text.isNotEmpty || _isFocused;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => _internalFocus.requestFocus(),
          child: Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: hasError
                    ? const Color(0xFFEF4444)
                    : _isFocused
                        ? const Color(0xFF2C3BD5)
                        : const Color(0xFFE2E8F0),
                width: _isFocused || hasError ? 1.5 : 1.2,
              ),
            ),
            child: Stack(
              children: [
                // TextFormField positioned at the bottom of the container
                TextFormField(
                  controller: widget.controller,
                  focusNode: _internalFocus,
                  obscureText: widget.obscureText,
                  keyboardType: widget.keyboardType,
                  textInputAction: widget.textInputAction,
                  onFieldSubmitted: widget.onSubmitted,
                  textAlign: TextAlign.left,
                  style: const TextStyle(
                    fontSize: 14.5,
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.only(top: 26, bottom: 6),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    filled: false,
                    fillColor: Colors.transparent,
                    errorStyle: TextStyle(
                      color: Colors.transparent,
                      fontSize: 0,
                      height: 0,
                    ),
                  ),
                  validator: (value) {
                    if (widget.validator != null) {
                      final err = widget.validator!(value);
                      if (_errorText != err) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) {
                            setState(() {
                              _errorText = err;
                            });
                          }
                        });
                      }
                      return err;
                    }
                    return null;
                  },
                ),
                // Smooth animated floating label and icon
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  left: 0,
                  top: isFloated ? 6 : 20,
                  child: IgnorePointer(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.icon != null) ...[
                          Icon(
                            widget.icon,
                            size: isFloated ? 14 : 18,
                            color: _isFocused
                                ? const Color(0xFF2C3BD5)
                                : const Color(0xFF94A3B8),
                          ),
                          const SizedBox(width: 8),
                        ],
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: TextStyle(
                            color: _isFocused
                                ? const Color(0xFF2C3BD5)
                                : const Color(0xFF94A3B8),
                            fontSize: isFloated ? 11 : 14.5,
                            fontWeight: isFloated ? FontWeight.w600 : FontWeight.w400,
                          ),
                          child: Text(widget.label),
                        ),
                      ],
                    ),
                  ),
                ),
                // Suffix (like Visibility Toggle)
                if (widget.suffix != null)
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: widget.suffix!,
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Text(
              _errorText!,
              style: const TextStyle(
                color: Color(0xFFEF4444),
                fontSize: 11,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Gradient-filled primary button
// ─────────────────────────────────────────────────────────────

class _GradientButton extends StatefulWidget {
  final String label;
  final bool isLoading;
  final VoidCallback? onPressed;

  const _GradientButton({
    required this.label,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  State<_GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<_GradientButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onPressed == null;

    return GestureDetector(
      onTapDown: (_) {
        if (!isDisabled && !widget.isLoading) {
          setState(() => _pressed = true);
        }
      },
      onTapUp: (_) {
        if (!isDisabled && !widget.isLoading) {
          setState(() => _pressed = false);
          widget.onPressed!();
        }
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 80),
        child: Container(
          height: 54,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: isDisabled
                ? const LinearGradient(
                    colors: [
                      Color(0xFFCBD5E1),
                      Color(0xFF94A3B8),
                    ],
                  )
                : const LinearGradient(
                    colors: [
                      Color(0xFF2537D5), // Start: vibrant blue
                      Color(0xFFD362EC), // End: light purple/pink
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: isDisabled
                ? null
                : [
                    BoxShadow(
                      color: const Color(0xFF2537D5).withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          alignment: Alignment.center,
          child: widget.isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : Text(
                  widget.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
        ),
      ),
    );
  }
}
