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

// Color tokens (shared with login screen)
const _teal = Color(0xFF0D7E8A);
const _tealLink = Color(0xFF10B4C3);
const _dark = Color(0xFF0F172A);
const _grey = Color(0xFF94A3B8);
const _border = Color(0xFFE2E8F0);
const _bgDark1 = Color(0xFF07242B); // matches login exactly
const _bgDark2 = Color(0xFF0F4850); // matches login exactly

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

  // Focus nodes — needed to detect when the user leaves a field
  final _phoneFocus = FocusNode();
  final _emailFocus = FocusNode();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _rememberMe = false;
  bool _isLoading = false;

  // Inline duplicate errors (set after focus-out async check)
  String? _phoneError;
  String? _emailError;
  bool _checkingPhone = false;
  bool _checkingEmail = false;

  @override
  void initState() {
    super.initState();

    // Check phone uniqueness when user leaves the phone field
    _phoneFocus.addListener(() {
      if (!_phoneFocus.hasFocus) _checkPhone();
    });

    // Check email uniqueness when user leaves the email field
    _emailFocus.addListener(() {
      if (!_emailFocus.hasFocus) _checkEmail();
    });
  }

  /// Async check: is this phone already registered?
  Future<void> _checkPhone() async {
    final phone = _phoneCtrl.text.trim();
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length != 10) return; // let the format validator handle it

    setState(() => _checkingPhone = true);
    final taken = await ref.read(authProvider.notifier).isPhoneTaken(phone);
    if (!mounted) return;
    setState(() {
      _checkingPhone = false;
      _phoneError = taken
          ? 'This phone number is already registered. Please use a different number.'
          : null;
    });
    _formKey.currentState?.validate(); // refresh inline error immediately
  }

  /// Async check: is this email already registered?
  Future<void> _checkEmail() async {
    final email = _emailCtrl.text.trim();
    if (!email.contains('@')) return; // let the format validator handle it

    setState(() => _checkingEmail = true);
    final taken = await ref.read(authProvider.notifier).isEmailTaken(email);
    if (!mounted) return;
    setState(() {
      _checkingEmail = false;
      _emailError = taken
          ? 'This email is already registered. Please sign in instead.'
          : null;
    });
    _formKey.currentState?.validate(); // refresh inline error immediately
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
    // Force async checks on both fields before final validate
    if (_phoneFocus.hasFocus || _emailFocus.hasFocus) {
      FocusScope.of(context).unfocus();
      await Future.delayed(const Duration(milliseconds: 300));
    }
    if (!_formKey.currentState!.validate()) return;
    // Guard: block if inline duplicate errors are still set
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
      // Server-side duplicate errors (edge case: race condition)
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
    // Signup has one extra field so keep the logo zone a touch smaller
    final topSectionHeight = screenHeight * 0.30;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: _bgDark1,
      body: Stack(
        children: [
          // ── Full-screen gradient + blob background (same as login) ──
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [_bgDark1, _bgDark2],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: CustomPaint(painter: _AuthBgPainter()),
            ),
          ),

          // Logo centered in the top section
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: topSectionHeight,
            child: SafeArea(
              bottom: false,
              child: Center(
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 80,
                  height: 80,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const _FallbackLogo(),
                ).animate().fadeIn(duration: 700.ms).scale(
                    begin: const Offset(0.75, 0.75), curve: Curves.easeOutBack),
              ),
            ),
          ),

          // White bottom-sheet form card
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            top: topSectionHeight - 30,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(28, 26, 28, 24),
                child: _buildForm(),
              ),
            ).animate(delay: 150.ms).slideY(
                begin: 0.08, end: 0, duration: 500.ms, curve: Curves.easeOut),
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
            'Sign Up',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: _dark,
              letterSpacing: -0.3,
            ),
          ).animate().fadeIn(delay: 200.ms),

          const SizedBox(height: 6),

          // Subtitle
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Flexible(
                child: Text(
                  'Already Have An Account? ',
                  style: TextStyle(fontSize: 13.5, color: _grey),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              GestureDetector(
                onTap: () => context.go(AppRoutes.login),
                child: const Text(
                  'Sign In',
                  style: TextStyle(
                    fontSize: 13.5,
                    color: _tealLink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ).animate().fadeIn(delay: 240.ms),

          const SizedBox(height: 20),

          // Full Name
          _AuthField(
            controller: _fullNameCtrl,
            hint: 'Enter your full name',
            prefixIcon: Icons.person_outline_rounded,
            textInputAction: TextInputAction.next,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Full name is required';
              if (v.trim().length < 2) return 'Name is too short';
              return null;
            },
          ).animate().fadeIn(delay: 255.ms),

          const SizedBox(height: 12),

          // Phone Number
          Stack(
            children: [
              _AuthField(
                controller: _phoneCtrl,
                focusNode: _phoneFocus,
                hint: '98XXXXXXXX',
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
                  if (digits.length != 10) return 'Phone number must be exactly 10 digits';
                  if (_phoneError != null) return _phoneError;
                  return null;
                },
              ),
              if (_checkingPhone)
                const Positioned(
                  right: 16,
                  top: 16,
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: _teal),
                  ),
                ),
            ],
          ).animate().fadeIn(delay: 265.ms),

          const SizedBox(height: 12),

          // Email
          Stack(
            children: [
              _AuthField(
                controller: _emailCtrl,
                focusNode: _emailFocus,
                hint: 'Enter your email address',
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
                  top: 16,
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: _teal),
                  ),
                ),
            ],
          ).animate().fadeIn(delay: 270.ms),

          const SizedBox(height: 12),

          // Password
          _AuthField(
            controller: _passwordCtrl,
            hint: 'Password',
            prefixIcon: Icons.lock_outline_rounded,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.next,
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
          ).animate().fadeIn(delay: 300.ms),

          const SizedBox(height: 12),

          // Confirm Password
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
                _obscureConfirm
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 20,
                color: _grey,
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Please confirm password';
              if (v != _passwordCtrl.text) return 'Passwords do not match';
              return null;
            },
          ).animate().fadeIn(delay: 330.ms),

          const SizedBox(height: 14),

          // Remember me + Forgot password
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: Checkbox(
                      value: _rememberMe,
                      onChanged: (v) =>
                          setState(() => _rememberMe = v ?? false),
                      activeColor: _teal,
                      checkColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4)),
                      side: BorderSide(
                          color: _rememberMe ? _teal : _border, width: 1.5),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('Remember Me',
                      style: TextStyle(fontSize: 13, color: _dark)),
                ],
              ),
              GestureDetector(
                onTap: () => context.push(AppRoutes.forgotPassword),
                child: const Text(
                  'Forgot Password?',
                  style: TextStyle(
                      fontSize: 13,
                      color: _tealLink,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ).animate().fadeIn(delay: 360.ms),

          const SizedBox(height: 18),

          // Sign Up button
          _PillButton(
            label: 'Sign Up',
            isLoading: _isLoading,
            onPressed: _signup,
          ).animate().fadeIn(delay: 390.ms),

          const SizedBox(height: 18),

          // Divider
          const Row(children: [
            Expanded(child: Divider(color: _border, thickness: 1)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 14),
              child: Text(
                'Or Continue With',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF9E9E9E),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(child: Divider(color: _border, thickness: 1)),
          ]).animate().fadeIn(delay: 420.ms),

          const SizedBox(height: 16),

          // Social buttons
          Row(
            children: [
              Expanded(
                child: _SocialPillButton(
                  label: 'Apple',
                  icon: const FaIcon(FontAwesomeIcons.apple,
                      size: 20, color: Colors.white),
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
          ).animate().fadeIn(delay: 450.ms),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Shared auth background painter — identical to login screen
// ─────────────────────────────────────────────────────────────

class _AuthBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final W = size.width;
    final H = size.height;

    // ── 1. Primary hero orb — top-left, large, rich teal ─────
    _drawOrb(
      canvas,
      center: Offset(W * -0.05, H * 0.05),
      radius: W * 0.80,
      colors: [
        const Color(0xFF1FE0F0).withValues(alpha: 0.55),
        const Color(0xFF0DA8B8).withValues(alpha: 0.22),
        Colors.transparent,
      ],
      stops: const [0.0, 0.45, 1.0],
    );

    // ── 2. Secondary orb — upper-right, cool cyan ─────────────
    _drawOrb(
      canvas,
      center: Offset(W * 1.05, H * -0.02),
      radius: W * 0.55,
      colors: [
        const Color(0xFF38EAF7).withValues(alpha: 0.38),
        const Color(0xFF0B7A87).withValues(alpha: 0.14),
        Colors.transparent,
      ],
      stops: const [0.0, 0.50, 1.0],
    );

    // ── 3. Mid orb — center-left, warm teal-indigo blend ──────
    _drawOrb(
      canvas,
      center: Offset(W * 0.20, H * 0.42),
      radius: W * 0.50,
      colors: [
        const Color(0xFF0CCEDF).withValues(alpha: 0.18),
        const Color(0xFF0A3D6B).withValues(alpha: 0.08),
        Colors.transparent,
      ],
      stops: const [0.0, 0.55, 1.0],
    );

    // ── 4. Diagonal aurora / light beam ───────────────────────
    final beamPath = Path()
      ..moveTo(W * -0.10, H * 0.30)
      ..lineTo(W * 0.45, H * 0.00)
      ..lineTo(W * 0.65, H * 0.00)
      ..lineTo(W * 0.10, H * 0.30)
      ..close();
    canvas.drawPath(
      beamPath,
      Paint()
        ..shader = LinearGradient(
          colors: [
            const Color(0xFF1FE0F0).withValues(alpha: 0.22),
            Colors.transparent,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromLTWH(0, 0, W, H * 0.30)),
    );

    // ── 5. Upper wave band ─────────────────────────────────────
    _drawWave(
      canvas,
      W,
      H,
      y1: 0.16,
      cp1x: 0.28,
      cp1y: 0.09,
      cp2x: 0.65,
      cp2y: 0.23,
      y2: 0.20,
      color: const Color(0xFF0ECFDD).withValues(alpha: 0.13),
    );

    // ── 6. Second wave band (offset) ──────────────────────────
    _drawWave(
      canvas,
      W,
      H,
      y1: 0.24,
      cp1x: 0.30,
      cp1y: 0.14,
      cp2x: 0.68,
      cp2y: 0.30,
      y2: 0.28,
      color: const Color(0xFF0BBAC8).withValues(alpha: 0.09),
    );

    // ── 7. Bottom dark swoosh ──────────────────────────────────
    final swoosh = Path()
      ..moveTo(0, H * 0.70)
      ..cubicTo(W * 0.25, H * 0.55, W * 0.75, H * 0.78, W, H * 0.62)
      ..lineTo(W, H)
      ..lineTo(0, H)
      ..close();
    canvas.drawPath(
      swoosh,
      Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.black.withValues(alpha: 0.22),
            Colors.black.withValues(alpha: 0.06),
          ],
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
        ).createShader(Rect.fromLTWH(0, H * 0.60, W, H * 0.40)),
    );

    // ── 8. Concentric glowing rings — left anchor ─────────────
    _drawRing(canvas, Offset(W * -0.02, H * 0.14), W * 0.46,
        const Color(0xFF1DD8E8).withValues(alpha: 0.18), 1.4);
    _drawRing(canvas, Offset(W * -0.02, H * 0.14), W * 0.62,
        const Color(0xFF1DD8E8).withValues(alpha: 0.10), 0.9);
    _drawRing(canvas, Offset(W * -0.02, H * 0.14), W * 0.80,
        const Color(0xFF1DD8E8).withValues(alpha: 0.05), 0.6);

    // ── 9. Scattered sparkle dots ─────────────────────────────
    final sparkles = [
      (W * 0.78, H * 0.05, 2.8),
      (W * 0.85, H * 0.02, 1.8),
      (W * 0.91, H * 0.07, 3.2),
      (W * 0.82, H * 0.11, 1.5),
      (W * 0.95, H * 0.03, 2.2),
      (W * 0.88, H * 0.20, 2.0),
      (W * 0.94, H * 0.25, 1.4),
      (W * 0.80, H * 0.28, 2.5),
      (W * 0.12, H * 0.30, 1.6),
      (W * 0.06, H * 0.34, 2.2),
      (W * 0.18, H * 0.32, 1.2),
    ];
    for (final s in sparkles) {
      canvas.drawCircle(
        Offset(s.$1, s.$2),
        s.$3 * 2.8,
        Paint()..color = const Color(0xFF1DD8E8).withValues(alpha: 0.10),
      );
      canvas.drawCircle(
        Offset(s.$1, s.$2),
        s.$3,
        Paint()..color = const Color(0xFF6FF6FF).withValues(alpha: 0.75),
      );
    }

    // ── 10. Subtle horizontal shimmer line ────────────────────
    canvas.drawLine(
      Offset(0, H * 0.295),
      Offset(W, H * 0.295),
      Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.transparent,
            const Color(0xFF1DD8E8).withValues(alpha: 0.25),
            Colors.transparent,
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(Rect.fromLTWH(0, H * 0.295, W, 1))
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke,
    );
  }

  void _drawOrb(
    Canvas canvas, {
    required Offset center,
    required double radius,
    required List<Color> colors,
    required List<double> stops,
  }) {
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(colors: colors, stops: stops)
            .createShader(Rect.fromCircle(center: center, radius: radius)),
    );
  }

  void _drawWave(
    Canvas canvas,
    double W,
    double H, {
    required double y1,
    required double cp1x,
    required double cp1y,
    required double cp2x,
    required double cp2y,
    required double y2,
    required Color color,
  }) {
    final path = Path()
      ..moveTo(0, H * y1)
      ..cubicTo(W * cp1x, H * cp1y, W * cp2x, H * cp2y, W, H * y2)
      ..lineTo(W, 0)
      ..lineTo(0, 0)
      ..close();
    canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.fill);
  }

  void _drawRing(Canvas canvas, Offset c, double r, Color color, double width) {
    canvas.drawCircle(
        c,
        r,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = width);
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

// ─────────────────────────────────────────────────────────────
//  Fallback Logo
// ─────────────────────────────────────────────────────────────

class _FallbackLogo extends StatelessWidget {
  const _FallbackLogo();
  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: const Size(80, 80), painter: _ArrowLogoPainter());
}

class _ArrowLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final w = size.width;
    final h = size.height;
    final outer = Path()
      ..moveTo(w * 0.5, h * 0.05)
      ..lineTo(w * 0.95, h * 0.92)
      ..lineTo(w * 0.05, h * 0.92)
      ..close();
    canvas.drawPath(outer, paint);
    final inner = Path()
      ..moveTo(w * 0.5, h * 0.30)
      ..lineTo(w * 0.68, h * 0.68)
      ..lineTo(w * 0.50, h * 0.55)
      ..lineTo(w * 0.32, h * 0.68)
      ..close();
    canvas.drawPath(inner, paint..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

// ─────────────────────────────────────────────────────────────
//  Auth Text Field
// ─────────────────────────────────────────────────────────────

class _AuthField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final IconData prefixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final void Function(String)? onSubmitted;
  final Widget? suffix;
  final FocusNode? focusNode;
  final List<TextInputFormatter>? inputFormatters;

  const _AuthField({
    required this.controller,
    required this.hint,
    required this.prefixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction,
    this.validator,
    this.onSubmitted,
    this.suffix,
    this.focusNode,
    this.inputFormatters,
  });

  @override
  State<_AuthField> createState() => _AuthFieldState();
}

class _AuthFieldState extends State<_AuthField> {
  late FocusNode _internalFocus;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    // Use the external FocusNode if provided, otherwise create our own
    _internalFocus = widget.focusNode ?? FocusNode();
    _internalFocus.addListener(
        () => setState(() => _focused = _internalFocus.hasFocus));
  }

  @override
  void dispose() {
    // Only dispose if we created the node ourselves
    if (widget.focusNode == null) _internalFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (v) => setState(() => _focused = v),
      child: TextFormField(
        controller: widget.controller,
        focusNode: _internalFocus,
        keyboardType: widget.keyboardType,
        obscureText: widget.obscureText,
        textInputAction: widget.textInputAction,
        inputFormatters: widget.inputFormatters,
        validator: widget.validator,
        onFieldSubmitted: widget.onSubmitted,
        style: const TextStyle(
            fontSize: 14.5, color: _dark, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: const TextStyle(
              color: _grey, fontSize: 14.5, fontWeight: FontWeight.w400),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 18, right: 10),
            child: Icon(widget.prefixIcon,
                size: 20, color: _focused ? _teal : _grey),
          ),
          prefixIconConstraints:
              const BoxConstraints(minWidth: 0, minHeight: 0),
          suffixIcon: widget.suffix != null
              ? Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: widget.suffix)
              : null,
          suffixIconConstraints:
              const BoxConstraints(minWidth: 0, minHeight: 0),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(50),
              borderSide: const BorderSide(color: _border, width: 1.2)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(50),
              borderSide: const BorderSide(color: _teal, width: 1.5)),
          errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(50),
              borderSide:
                  const BorderSide(color: Color(0xFFEF4444), width: 1.2)),
          focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(50),
              borderSide:
                  const BorderSide(color: Color(0xFFEF4444), width: 1.5)),
          border: InputBorder.none,
          errorStyle: const TextStyle(fontSize: 11, color: Color(0xFFEF4444)),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Pill primary button
// ─────────────────────────────────────────────────────────────

class _PillButton extends StatefulWidget {
  final String label;
  final bool isLoading;
  final VoidCallback onPressed;
  const _PillButton(
      {required this.label, required this.isLoading, required this.onPressed});
  @override
  State<_PillButton> createState() => _PillButtonState();
}

class _PillButtonState extends State<_PillButton> {
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
          height: 52,
          width: double.infinity,
          decoration: BoxDecoration(
            color: _pressed ? const Color(0xFF0A6872) : _teal,
            borderRadius: BorderRadius.circular(50),
          ),
          alignment: Alignment.center,
          child: widget.isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: Colors.white))
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
//  Google logo SVG
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
//  Social pill button
// ─────────────────────────────────────────────────────────────

class _SocialPillButton extends StatelessWidget {
  final String label;
  final Widget icon;
  final bool isDark;
  final VoidCallback onTap;
  const _SocialPillButton(
      {required this.label,
      required this.icon,
      required this.isDark,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: isDark ? _dark : Colors.white,
          borderRadius: BorderRadius.circular(50),
          border: isDark ? null : Border.all(color: _border, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
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
