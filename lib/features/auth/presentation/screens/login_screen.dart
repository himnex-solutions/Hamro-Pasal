import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:hamro_pasal/core/router/app_router.dart';
import 'package:hamro_pasal/core/widgets/app_snackbar.dart';
import 'package:hamro_pasal/features/auth/presentation/providers/auth_provider.dart';

import 'package:hamro_pasal/core/widgets/wavy_divider.dart';

// ── Color tokens (matching reference image exactly) ────────────
const _gradientStart = Color(0xFF1E2ED2); // royal blue
const _gradientEnd = Color(0xFF6B58F5); // light purple/blue
const _dark = Color(0xFF0F172A); // slate-black for titles
const _grey = Color(0xFF94A3B8); // slate-grey for subtitle
const _border = Color(0xFFE2E8F0); // border color

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
  bool _rememberMe = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  // ── Auth logic ────────────────────────────────────────────────
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
      final s = ref.read(authProvider);
      switch (s.status) {
        case AuthStatus.needsOtpVerification:
          context.push(AppRoutes.otpVerification,
              extra: s.pendingEmail ?? _emailCtrl.text.trim());
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
      AppSnackbar.show(
          context, ref.read(authProvider).errorMessage ?? 'Login failed',
          isError: true);
    }
  }

  Future<void> _googleLogin() async {
    setState(() => _isLoading = true);
    final success = await ref.read(authProvider.notifier).signInWithGoogle();
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (success) {
      final s = ref.read(authProvider);
      context.go(s.status == AuthStatus.needsBusinessSetup
          ? AppRoutes.businessSetup
          : AppRoutes.dashboard);
    }
  }

  // ── Build ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final topSectionHeight = screenHeight * 0.38;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: _gradientStart,
      body: Stack(
        children: [
          // ── Top Gradient Section ──────────────────
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [_gradientStart, _gradientEnd],
                  begin: Alignment.bottomLeft,
                  end: Alignment.topRight,
                ),
              ),
            ),
          ),

          // ── Top Navigation Row ──────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Back Arrow Button
                    GestureDetector(
                      onTap: () {
                        if (Navigator.of(context).canPop()) {
                          context.pop();
                        }
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Title "HamroPasal" centered in top section ──────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: topSectionHeight,
            child: SafeArea(
              bottom: false,
              child: Center(
                child: const Text(
                  'HamroPasal',
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.6,
                  ),
                ).animate().fadeIn(duration: 700.ms).scale(
                    begin: const Offset(0.9, 0.9), curve: Curves.easeOutBack),
              ),
            ),
          ),

          // ── White bottom-sheet card with wavy divider ───────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            top: topSectionHeight - 45, // slight overlap to display waves beautifully
            child: WavyDivider(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(left: 24, right: 24, top: 60, bottom: 32),
                child: _buildForm(),
              ),
            ).animate(delay: 150.ms).slideY(
                begin: 0.08, end: 0, duration: 500.ms, curve: Curves.easeOut),
          ),
        ],
      ),
    );
  }

  // ── Form ──────────────────────────────────────────────────────
  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),

          // Email
          _CustomAuthField(
            controller: _emailCtrl,
            label: 'Email Address',
            icon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Email is required';
              if (!v.contains('@')) return 'Enter a valid email';
              return null;
            },
          ).animate().fadeIn(delay: 280.ms),

          const SizedBox(height: 16),

          // Password
          _CustomAuthField(
            controller: _passwordCtrl,
            label: 'Password',
            icon: Icons.lock_outline_rounded,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _login(),
            suffix: GestureDetector(
              onTap: () => setState(() => _obscurePassword = !_obscurePassword),
              child: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 20,
                color: _grey,
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Password is required';
              if (v.length < 6) return 'Minimum 6 characters';
              return null;
            },
          ).animate().fadeIn(delay: 310.ms),

          const SizedBox(height: 18),

          // Remember Me & Forgot Password Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Remember Me Checkbox
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: Checkbox(
                      value: _rememberMe,
                      onChanged: (val) {
                        setState(() {
                          _rememberMe = val ?? false;
                        });
                      },
                      activeColor: const Color(0xFF2C3BD5),
                      checkColor: Colors.white,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                      side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => setState(() => _rememberMe = !_rememberMe),
                    child: const Text(
                      'Remember me',
                      style: TextStyle(
                        fontSize: 13.5,
                        color: Color(0xFF475569),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              // Forgot Password
              GestureDetector(
                onTap: () => context.push(AppRoutes.forgotPassword),
                child: const Text(
                  'Forgot password?',
                  style: TextStyle(
                    fontSize: 13.5,
                    color: Color(0xFF475569),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ).animate().fadeIn(delay: 325.ms),

          const SizedBox(height: 28),

          // Sign in button
          _GradientButton(
            label: 'Sign in',
            isLoading: _isLoading,
            onPressed: _login,
          ).animate().fadeIn(delay: 340.ms),

          const SizedBox(height: 24),

          // Divider
          const Row(children: [
            Expanded(child: Divider(color: _border, thickness: 1)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Or sign in with',
                style: TextStyle(
                  fontSize: 13,
                  color: _grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(child: Divider(color: _border, thickness: 1)),
          ]).animate().fadeIn(delay: 400.ms),

          const SizedBox(height: 22),

          // Social buttons row
          Row(
            children: [
              // Google
              Expanded(
                child: _SocialBorderButton(
                  label: 'Google',
                  icon: _GoogleLogo(),
                  textColor: _dark,
                  onTap: _googleLogin,
                ),
              ),
              const SizedBox(width: 16),
              // Apple
              Expanded(
                child: _SocialBorderButton(
                  label: 'Apple',
                  icon: const Icon(
                    Icons.apple,
                    color: Colors.black,
                    size: 24,
                  ),
                  textColor: Colors.black,
                  onTap: () {
                    AppSnackbar.show(
                      context,
                      'Apple login is not configured yet.',
                      isError: false,
                    );
                  },
                ),
              ),
            ],
          ).animate().fadeIn(delay: 430.ms),

          const SizedBox(height: 28),

          // Don't have an account? Sign Up
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Don't have an account? ",
                style: TextStyle(
                  color: Color(0xFF64748B), // Slate 500
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              GestureDetector(
                onTap: () => context.push(AppRoutes.signup),
                child: const Text(
                  'Sign Up',
                  style: TextStyle(
                    color: Color(0xFF2C3BD5), // Accent blue
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ).animate().fadeIn(delay: 450.ms),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Custom Auth Text Field (label-inside-border custom design)
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
  final VoidCallback onPressed;

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
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        if (!widget.isLoading) widget.onPressed();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 80),
        child: Container(
          height: 54,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF2537D5), // Start: vibrant blue
                Color(0xFFD362EC), // End: light purple/pink
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
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

// ─────────────────────────────────────────────────────────────
//  Google SVG Logo
// ─────────────────────────────────────────────────────────────

class _GoogleLogo extends StatelessWidget {
  static const _svg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
  <path fill="#FFC107" d="M43.6 20H24v8h11.3C33.7 33.1 29.3 36 24 36c-6.6 0-12-5.4-12-12s5.4-12 12-12c3.1 0 5.8 1.1 8 3l5.6-5.6C34 6.1 29.3 4 24 4 12.9 4 4 12.9 4 24s8.9 20 20 20c11 0 20-9 20-20 0-1.3-.2-2.7-.4-4z"/>
  <path fill="#FF3D00" d="M6.3 14.7l6.6 4.8C14.7 15.1 19 12 24 12c3.1 0 5.8 1.1 8 3l5.6-5.6C34 6.1 29.3 4 24 4 16.3 4 9.7 8.3 6.3 14.7z"/>
  <path fill="#4CAF50" d="M24 44c5.2 0 9.9-2 13.4-5.2l-6.2-5.2C29.2 35.1 26.7 36 24 36c-5.2 0-9.6-3.3-11.3-7.9l-6.5 5C9.5 39.6 16.2 44 24 44z"/>
  <path fill="#1976D2" d="M43.6 20H24v8h11.3c-.8 2.2-2.2 4.2-4.1 5.6l6.2 5.2C41 36 44 30.5 44 24c0-1.3-.2-2.7-.4-4z"/>
</svg>''';

  @override
  Widget build(BuildContext context) =>
      SvgPicture.string(_svg, width: 22, height: 22);
}

// ─────────────────────────────────────────────────────────────
//  Social Login Border Button
// ─────────────────────────────────────────────────────────────

class _SocialBorderButton extends StatelessWidget {
  final String label;
  final Widget icon;
  final Color textColor;
  final VoidCallback onTap;

  const _SocialBorderButton({
    required this.label,
    required this.icon,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
