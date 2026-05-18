import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:hamro_pasal/core/router/app_router.dart';
import 'package:hamro_pasal/core/widgets/app_snackbar.dart';
import 'package:hamro_pasal/core/widgets/poly_mesh_background.dart';
import 'package:hamro_pasal/features/auth/presentation/providers/auth_provider.dart';

// ── Color tokens (matching reference image exactly) ────────────
const _teal = Color(0xFF0D7E8A); // dark teal for button & accents
const _tealLink = Color(0xFF10B4C3); // slightly brighter for links
const _dark = Color(0xFF0F172A); // near-black title text
const _grey = Color(0xFF94A3B8); // placeholder / secondary text
const _border = Color(0xFFE2E8F0); // input border
const _bgDark1 = Color(0xFF07242B); // top-left of background gradient
const _bgDark2 = Color(0xFF0F4850); // bottom-right of background gradient

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
  bool _rememberMe = false;
  bool _isLoading = false;

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
    // Card covers ~63% of screen; logo sits in the top ~37%
    final topSectionHeight = screenHeight * 0.37;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: _bgDark1,
      body: Stack(
        children: [
          // ── Full-screen polygonal dark background ─────────────
          const Positioned.fill(
            child: PolyMeshBackground(),
          ),

          // ── Logo centered in the top section ──────────────────
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
                  width: 90,
                  height: 90,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const _FallbackLogo(),
                ).animate().fadeIn(duration: 700.ms).scale(
                    begin: const Offset(0.75, 0.75), curve: Curves.easeOutBack),
              ),
            ),
          ),

          // ── White bottom-sheet card ───────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            top: topSectionHeight - 30, // slight overlap with dark bg
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(28, 30, 28, 24),
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
          // Title
          const Text(
            'Login',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: _dark,
              letterSpacing: -0.3,
            ),
          ).animate().fadeIn(delay: 200.ms),

          const SizedBox(height: 6),

          // Subtitle row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Flexible(
                child: Text(
                  "Don't Have An Account? ",
                  style: TextStyle(fontSize: 13.5, color: _grey),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              GestureDetector(
                onTap: () => context.push(AppRoutes.signup),
                child: const Text(
                  'Sign Up',
                  style: TextStyle(
                    fontSize: 13.5,
                    color: _tealLink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ).animate().fadeIn(delay: 240.ms),

          const SizedBox(height: 26),

          // Email
          _AuthField(
            controller: _emailCtrl,
            hint: 'Enter your email address',
            prefixIcon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Email is required';
              if (!v.contains('@')) return 'Enter a valid email';
              return null;
            },
          ).animate().fadeIn(delay: 280.ms),

          const SizedBox(height: 14),

          // Password
          _AuthField(
            controller: _passwordCtrl,
            hint: 'Password',
            prefixIcon: Icons.lock_outline_rounded,
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

          const SizedBox(height: 14),

          // Remember me + Forgot password
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Checkbox + label
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
                  const Text(
                    'Remember Me',
                    style: TextStyle(fontSize: 13, color: _dark),
                  ),
                ],
              ),
              // Forgot
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
          ).animate().fadeIn(delay: 340.ms),

          const SizedBox(height: 22),

          // Login button
          _PillButton(
            label: 'Login',
            isLoading: _isLoading,
            onPressed: _login,
          ).animate().fadeIn(delay: 370.ms),

          const SizedBox(height: 20),

          // Divider
          Row(children: [
            Expanded(child: Divider(color: _border, thickness: 1)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Text(
                'Or Continue With',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(child: Divider(color: _border, thickness: 1)),
          ]).animate().fadeIn(delay: 400.ms),

          const SizedBox(height: 18),

          // Social buttons row
          Row(
            children: [
              // Apple
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
              // Google
              Expanded(
                child: _SocialPillButton(
                  label: 'Google',
                  icon: _GoogleLogo(),
                  isDark: false,
                  onTap: _googleLogin,
                ),
              ),
            ],
          ).animate().fadeIn(delay: 430.ms),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Fallback Logo (white outline triangle/arrow)
// ─────────────────────────────────────────────────────────────

class _FallbackLogo extends StatelessWidget {
  const _FallbackLogo();
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(80, 80),
      painter: _ArrowLogoPainter(),
    );
  }
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

    // Outer triangle
    final outer = Path()
      ..moveTo(w * 0.5, h * 0.05)
      ..lineTo(w * 0.95, h * 0.92)
      ..lineTo(w * 0.05, h * 0.92)
      ..close();
    canvas.drawPath(outer, paint);

    // Inner arrow pointing up
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
//  Auth Text Field (pill-shaped, matching reference)
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
        keyboardType: widget.keyboardType,
        obscureText: widget.obscureText,
        textInputAction: widget.textInputAction,
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
          // Pill-shaped borders (radius 50 = fully round sides)
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
//  Pill-shaped primary button
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
//  Social Button (pill-shaped)
// ─────────────────────────────────────────────────────────────

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
          borderRadius: BorderRadius.circular(50),
          border: isDark ? null : Border.all(color: _border, width: 1.2),
          boxShadow: isDark
              ? [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 8,
                      offset: const Offset(0, 2))
                ]
              : [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 1))
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
