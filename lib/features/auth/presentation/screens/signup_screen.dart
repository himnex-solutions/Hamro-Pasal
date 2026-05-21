import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:hamro_pasal/core/router/app_router.dart';
import 'package:hamro_pasal/core/widgets/app_snackbar.dart';
import 'package:hamro_pasal/features/auth/presentation/providers/auth_provider.dart';

// Color palette
const _teal = Color(0xFF0D7E8A);
const _tealLink = Color(0xFF10B4C3);
const _dark = Color(0xFF0F172A);
const _grey = Color(0xFF94A3B8);
const _border = Color(0xFFE2E8F0);

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});
  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  final _phoneFocus = FocusNode();
  final _emailFocus = FocusNode();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _rememberMe = false;
  bool _isLoading = false;

  String? _phoneError;
  String? _emailError;
  bool _checkingPhone = false;
  bool _checkingEmail = false;

  @override
  void initState() {
    super.initState();

    _phoneFocus.addListener(() {
      if (!_phoneFocus.hasFocus) _checkPhone();
    });

    _emailFocus.addListener(() {
      if (!_emailFocus.hasFocus) _checkEmail();
    });
  }

  Future<void> _checkPhone() async {
    final phone = _phoneCtrl.text.trim();
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length != 10) return;

    setState(() => _checkingPhone = true);
    final taken = await ref.read(authProvider.notifier).isPhoneTaken(phone);
    if (!mounted) return;
    setState(() {
      _checkingPhone = false;
      _phoneError = taken
          ? 'This phone number is already registered. Please use another.'
          : null;
    });
    _formKey.currentState?.validate();
  }

  Future<void> _checkEmail() async {
    final email = _emailCtrl.text.trim();
    if (!email.contains('@')) return;

    setState(() => _checkingEmail = true);
    final taken = await ref.read(authProvider.notifier).isEmailTaken(email);
    if (!mounted) return;
    setState(() {
      _checkingEmail = false;
      _emailError = taken
          ? 'This email is already registered. Please sign in instead.'
          : null;
    });
    _formKey.currentState?.validate();
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _phoneFocus.dispose();
    _emailFocus.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    if (_phoneFocus.hasFocus || _emailFocus.hasFocus) {
      FocusScope.of(context).unfocus();
      await Future.delayed(const Duration(milliseconds: 300));
    }
    if (!_formKey.currentState!.validate()) return;
    if (_phoneError != null || _emailError != null) return;
    setState(() => _isLoading = true);
    final success = await ref.read(authProvider.notifier).signUp(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
          fullName: _fullNameCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
        );
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (success) {
      AppSnackbar.show(
        context,
        'Account created! Please sign in.',
        isSuccess: true,
        duration: const Duration(seconds: 4),
      );
      context.go(AppRoutes.login);
    } else {
      final msg = ref.read(authProvider).errorMessage ?? 'Registration failed';
      if (msg.toLowerCase().contains('phone')) {
        setState(() => _phoneError = msg);
        _formKey.currentState?.validate();
      } else if (msg.toLowerCase().contains('email')) {
        setState(() => _emailError = msg);
        _formKey.currentState?.validate();
      } else {
        AppSnackbar.show(context, msg, isError: true);
      }
    }
  }

  Future<void> _googleSignup() async {
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

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final topSectionHeight = screenHeight * 0.26;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFF0B132B),
      body: Stack(
        children: [
          // ── Beautiful Mesh Glowing Background Orbs ───────────
          Positioned(
            top: -screenHeight * 0.05,
            left: -screenWidth * 0.2,
            child: Container(
              width: screenWidth * 1.1,
              height: screenWidth * 1.1,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF0D7E8A).withValues(alpha: 0.35),
                    const Color(0xFF0D7E8A).withValues(alpha: 0.0),
                  ],
                ),
              ),
            )
                .animate(onPlay: (controller) => controller.repeat(reverse: true))
                .scaleXY(begin: 1.0, end: 1.12, duration: 6.seconds, curve: Curves.easeInOut),
          ),
          Positioned(
            top: screenHeight * 0.12,
            right: -screenWidth * 0.3,
            child: Container(
              width: screenWidth * 1.2,
              height: screenWidth * 1.2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF6366F1).withValues(alpha: 0.25),
                    const Color(0xFF6366F1).withValues(alpha: 0.0),
                  ],
                ),
              ),
            )
                .animate(onPlay: (controller) => controller.repeat(reverse: true))
                .scaleXY(begin: 1.0, end: 1.15, duration: 8.seconds, curve: Curves.easeInOut),
          ),

          // ── Header Logo & Branding Zone ──────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: topSectionHeight,
            child: SafeArea(
              bottom: false,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF60A5FA), Color(0xFF1E6FD9)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1E6FD9).withValues(alpha: 0.4),
                          blurRadius: 28,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.store_rounded,
                      size: 38,
                      color: Colors.white,
                    ),
                  )
                      .animate()
                      .scale(duration: 600.ms, curve: Curves.elasticOut, begin: const Offset(0.4, 0.4))
                      .fadeIn(duration: 400.ms),
                  const SizedBox(height: 10),
                  const Text(
                    'Hamro Pasal',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ).animate(delay: 200.ms).fadeIn(),
                ],
              ),
            ),
          ),

          // ── Beautiful Sheet Form Card ──────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            top: topSectionHeight - 20,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 24,
                    offset: Offset(0, -6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(28, 28, 28, 32),
                  child: _buildForm(),
                ),
              ),
            ).animate(delay: 100.ms).slideY(
                begin: 0.1, end: 0, duration: 500.ms, curve: Curves.easeOut),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Title
          const Text(
            'Create Account',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: _dark,
              letterSpacing: -0.5,
            ),
          ).animate().fadeIn(delay: 150.ms),

          const SizedBox(height: 4),

          // Subtitle
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Already have an account? ',
                style: TextStyle(fontSize: 13, color: _grey),
              ),
              GestureDetector(
                onTap: () => context.go(AppRoutes.login),
                child: const Text(
                  'Sign In',
                  style: TextStyle(
                    fontSize: 13,
                    color: _tealLink,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ).animate().fadeIn(delay: 200.ms),

          const SizedBox(height: 24),

          // Full Name Input
          _AuthField(
            controller: _fullNameCtrl,
            hint: 'Full name',
            prefixIcon: Icons.person_outline_rounded,
            textInputAction: TextInputAction.next,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Full name is required';
              if (v.trim().length < 2) return 'Name is too short';
              return null;
            },
          ).animate().fadeIn(delay: 240.ms),

          const SizedBox(height: 12),

          // Phone Number Input
          Stack(
            alignment: Alignment.centerRight,
            children: [
              _AuthField(
                controller: _phoneCtrl,
                focusNode: _phoneFocus,
                hint: 'Phone number (98XXXXXXXX)',
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Phone number is required';
                  final digits = v.trim().replaceAll(RegExp(r'[^0-9]'), '');
                  if (digits.length != 10) return 'Must be exactly 10 digits';
                  if (_phoneError != null) return _phoneError;
                  return null;
                },
              ),
              if (_checkingPhone)
                const Positioned(
                  right: 16,
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: _teal),
                  ),
                ),
            ],
          ).animate().fadeIn(delay: 270.ms),

          const SizedBox(height: 12),

          // Email Input
          Stack(
            alignment: Alignment.centerRight,
            children: [
              _AuthField(
                controller: _emailCtrl,
                focusNode: _emailFocus,
                hint: 'Email address',
                prefixIcon: Icons.mail_outline_rounded,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Email is required';
                  if (!v.contains('@')) return 'Enter a valid email';
                  if (_emailError != null) return _emailError;
                  return null;
                },
              ),
              if (_checkingEmail)
                const Positioned(
                  right: 16,
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: _teal),
                  ),
                ),
            ],
          ).animate().fadeIn(delay: 300.ms),

          const SizedBox(height: 12),

          // Password Input
          _AuthField(
            controller: _passwordCtrl,
            hint: 'Password',
            prefixIcon: Icons.lock_outline_rounded,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.next,
            suffix: GestureDetector(
              onTap: () => setState(() => _obscurePassword = !_obscurePassword),
              child: Icon(
                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 20,
                color: _grey,
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Password is required';
              if (v.length < 6) return 'Minimum 6 characters';
              return null;
            },
          ).animate().fadeIn(delay: 330.ms),

          const SizedBox(height: 12),

          // Confirm Password Input
          _AuthField(
            controller: _confirmCtrl,
            hint: 'Confirm Password',
            prefixIcon: Icons.lock_outline_rounded,
            obscureText: _obscureConfirm,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _signup(),
            suffix: GestureDetector(
              onTap: () => setState(() => _obscureConfirm = !_obscureConfirm),
              child: Icon(
                _obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 20,
                color: _grey,
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Confirm your password';
              if (v != _passwordCtrl.text) return 'Passwords do not match';
              return null;
            },
          ).animate().fadeIn(delay: 360.ms),

          const SizedBox(height: 16),

          // Remember Me Checkbox
          Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: Checkbox(
                  value: _rememberMe,
                  onChanged: (v) => setState(() => _rememberMe = v ?? false),
                  activeColor: _teal,
                  checkColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                  side: BorderSide(color: _rememberMe ? _teal : _border, width: 1.5),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Remember Me',
                style: TextStyle(fontSize: 13, color: _dark, fontWeight: FontWeight.w500),
              ),
            ],
          ).animate().fadeIn(delay: 380.ms),

          const SizedBox(height: 24),

          // Premium Loading Button
          _PillButton(
            label: 'Sign Up',
            isLoading: _isLoading,
            onPressed: _signup,
          ).animate().fadeIn(delay: 400.ms),

          const SizedBox(height: 20),

          // Divider
          Row(
            children: [
              const Expanded(child: Divider(color: _border, thickness: 1)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Or Continue With',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade400, fontWeight: FontWeight.w600),
                ),
              ),
              const Expanded(child: Divider(color: _border, thickness: 1)),
            ],
          ).animate().fadeIn(delay: 440.ms),

          const SizedBox(height: 16),

          // Social Buttons
          Row(
            children: [
              Expanded(
                child: _SocialPillButton(
                  label: 'Apple',
                  icon: const FaIcon(FontAwesomeIcons.apple, size: 20, color: Colors.white),
                  isDark: true,
                  onTap: () {},
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _SocialPillButton(
                  label: 'Google',
                  icon: _GoogleLogo(),
                  isDark: false,
                  onTap: _googleSignup,
                ),
              ),
            ],
          ).animate().fadeIn(delay: 480.ms),
        ],
      ),
    );
  }
}

// ── Beautiful Focus-Driven Auth Field ──────────────────────────
class _AuthField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String hint;
  final IconData prefixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final void Function(String)? onSubmitted;
  final Widget? suffix;

  const _AuthField({
    required this.controller,
    this.focusNode,
    required this.hint,
    required this.prefixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction,
    this.inputFormatters,
    this.validator,
    this.onSubmitted,
    this.suffix,
  });

  @override
  State<_AuthField> createState() => _AuthFieldState();
}

class _AuthFieldState extends State<_AuthField> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (v) => setState(() => _focused = v),
      child: TextFormField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        keyboardType: widget.keyboardType,
        obscureText: widget.obscureText,
        textInputAction: widget.textInputAction,
        inputFormatters: widget.inputFormatters,
        validator: widget.validator,
        onFieldSubmitted: widget.onSubmitted,
        style: const TextStyle(fontSize: 14.5, color: _dark, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: const TextStyle(color: _grey, fontSize: 14, fontWeight: FontWeight.w400),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 18, right: 12),
            child: Icon(widget.prefixIcon, size: 20, color: _focused ? _teal : _grey),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
          suffixIcon: widget.suffix != null
              ? Padding(padding: const EdgeInsets.only(right: 16), child: widget.suffix)
              : null,
          suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
          filled: true,
          fillColor: _focused ? const Color(0xFFF0FDFA) : const Color(0xFFF8FAFC),
          contentPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: _border, width: 1.2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: _teal, width: 1.8),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.2),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.8),
          ),
          errorStyle: const TextStyle(fontSize: 11, color: Color(0xFFEF4444), fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}

// ── Premium Pill Button with Shimmer Wave effect ─────────────────
class _PillButton extends StatefulWidget {
  final String label;
  final bool isLoading;
  final VoidCallback onPressed;
  const _PillButton({
    required this.label,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  State<_PillButton> createState() => _PillButtonState();
}

class _PillButtonState extends State<_PillButton> with SingleTickerProviderStateMixin {
  bool _pressed = false;
  late AnimationController _shimmerCtrl;

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    if (widget.isLoading) {
      _shimmerCtrl.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant _PillButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoading && !oldWidget.isLoading) {
      _shimmerCtrl.repeat();
    } else if (!widget.isLoading && oldWidget.isLoading) {
      _shimmerCtrl.stop();
    }
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    super.dispose();
  }

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
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 80),
        child: Container(
          height: 52,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: _pressed
                  ? [const Color(0xFF096872), const Color(0xFF0D7E8A)]
                  : [const Color(0xFF0D7E8A), const Color(0xFF14B8A6)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0D7E8A).withValues(alpha: 0.35),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: widget.isLoading
              ? AnimatedBuilder(
                  animation: _shimmerCtrl,
                  builder: (context, child) {
                    return ShaderMask(
                      shaderCallback: (bounds) {
                        return LinearGradient(
                          colors: [
                            Colors.white.withValues(alpha: 0.3),
                            Colors.white,
                            Colors.white.withValues(alpha: 0.3),
                          ],
                          stops: [
                            (_shimmerCtrl.value - 0.25).clamp(0.0, 1.0),
                            _shimmerCtrl.value,
                            (_shimmerCtrl.value + 0.25).clamp(0.0, 1.0),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(bounds);
                      },
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Connecting...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                )
              : Text(
                  widget.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
        ),
      ),
    );
  }
}

// ── Google SVG Logo ──────────────────────────────────────────
class _GoogleLogo extends StatelessWidget {
  static const _svg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
  <path fill="#FFC107" d="M43.6 20H24v8h11.3C33.7 33.1 29.3 36 24 36c-6.6 0-12-5.4-12-12s5.4-12 12-12c3.1 0 5.8 1.1 8 3l5.6-5.6C34 6.1 29.3 4 24 4 12.9 4 4 12.9 4 24s8.9 20 20 20c11 0 20-9 20-20 0-1.3-.2-2.7-.4-4z"/>
  <path fill="#FF3D00" d="M6.3 14.7l6.6 4.8C14.7 15.1 19 12 24 12c3.1 0 5.8 1.1 8 3l5.6-5.6C34 6.1 29.3 4 24 4 16.3 4 9.7 8.3 6.3 14.7z"/>
  <path fill="#4CAF50" d="M24 44c5.2 0 9.9-2 13.4-5.2l-6.2-5.2C29.2 35.1 26.7 36 24 36c-5.2 0-9.6-3.3-11.3-7.9l-6.5 5C9.5 39.6 16.2 44 24 44z"/>
  <path fill="#1976D2" d="M43.6 20H24v8h11.3c-.8 2.2-2.2 4.2-4.1 5.6l6.2 5.2C41 36 44 30.5 44 24c0-1.3-.2-2.7-.4-4z"/>
</svg>''';

  @override
  Widget build(BuildContext context) => SvgPicture.string(_svg, width: 22, height: 22);
}

// ── Social Pill Button ─────────────────────────────────────────
class _SocialPillButton extends StatelessWidget {
  final String label;
  final Widget icon;
  final bool isDark;
  final VoidCallback onTap;

  const _SocialPillButton({
    required this.label,
    required this.icon,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: isDark ? _dark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isDark ? null : Border.all(color: _border, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isDark ? Colors.white : _dark,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
