import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:hamro_pasal/core/router/app_router.dart';
import 'package:hamro_pasal/core/widgets/app_snackbar.dart';
import 'package:hamro_pasal/features/auth/presentation/providers/auth_provider.dart';

const _teal = Color(0xFF0EA5B0);
const _tealLight = Color(0xFF14C1CC);
const _dark = Color(0xFF0F172A);
const _textSecondary = Color(0xFF94A3B8);
const _borderColor = Color(0xFFE5E7EB);

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
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
      AppSnackbar.show(context,
          ref.read(authProvider).errorMessage ?? 'Login failed',
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

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final topFlex = (screenHeight > 750) ? 42 : 38;
    final bottomFlex = 100 - topFlex;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: _teal,
      body: Stack(
        children: [
          // ── Gradient background ───────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [_tealLight, _teal, Color(0xFF0B8E99)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // ── Decorative circles ─────────────────────────────
          Positioned(
            top: -60, right: -40,
            child: _Circle(180, Colors.white.withValues(alpha: 0.07)),
          ),
          Positioned(
            top: 80, right: 30,
            child: _Circle(90, Colors.white.withValues(alpha: 0.05)),
          ),
          Positioned(
            top: screenHeight * 0.25, left: -30,
            child: _Circle(110, Colors.white.withValues(alpha: 0.05)),
          ),

          // ── Shopping-themed watermark icons ───────────────────
          // Large cart — bottom-left
          Positioned(
            bottom: screenHeight * 0.42, left: -8,
            child: const Icon(Icons.shopping_cart_outlined,
                color: Colors.white24, size: 80),
          ),
          // Shopping bag — top-right
          Positioned(
            top: screenHeight * 0.05, right: 20,
            child: const Icon(Icons.shopping_bag_outlined,
                color: Colors.white24, size: 52),
          ),
          // Price tag — mid-left
          Positioned(
            top: screenHeight * 0.16, left: 18,
            child: const Icon(Icons.local_offer_outlined,
                color: Colors.white12, size: 32),
          ),
          // Store — top-center-right
          Positioned(
            top: screenHeight * 0.02, left: screenHeight * 0.18,
            child: const Icon(Icons.storefront_outlined,
                color: Colors.white12, size: 28),
          ),
          // Package — mid area
          Positioned(
            top: screenHeight * 0.22, right: 10,
            child: const Icon(Icons.inventory_2_outlined,
                color: Colors.white12, size: 26),
          ),

          // ── Main layout ───────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                // ── Top: Headline ────────────────────────
                Expanded(
                  flex: topFlex,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(28, 16, 28, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: const TextSpan(
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              height: 1.25,
                            ),
                            children: [
                              TextSpan(text: 'Log in to stay on\n'),
                              TextSpan(
                                text: 'top of ',
                                style: TextStyle(color: Color(0xFFA7F3F8)),
                              ),
                              TextSpan(text: 'your tasks\nand projects.'),
                            ],
                          ),
                        ).animate().fadeIn(duration: 600.ms).slideX(begin: -0.05, end: 0),
                        const Spacer(),
                        Align(
                          alignment: Alignment.centerRight,
                          child: _PhoneMockup(),
                        ).animate(delay: 200.ms).fadeIn(),
                      ],
                    ),
                  ),
                ),

                // ── Bottom: White form (no scroll) ────────
                Expanded(
                  flex: bottomFlex,
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 10),
                      child: _buildForm(),
                    ),
                  ).animate(delay: 100.ms).slideY(
                      begin: 0.1, end: 0, duration: 450.ms, curve: Curves.easeOut),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Centered title ────────────────────────────
          const Text(
            'Login',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: _dark,
            ),
          ).animate().fadeIn(delay: 150.ms),

          const SizedBox(height: 8),

          // ── Centered subtitle ─────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Don't Have An Account? ",
                style: TextStyle(fontSize: 13, color: _textSecondary),
              ),
              GestureDetector(
                onTap: () => context.push(AppRoutes.signup),
                child: const Text(
                  'Sign Up',
                  style: TextStyle(
                      fontSize: 13, color: _teal, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ).animate().fadeIn(delay: 200.ms),

          const SizedBox(height: 20),

          // ── Email field ───────────────────────────────
          _AuthTextField(
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
          ).animate(delay: 220.ms).fadeIn(),

          const SizedBox(height: 10),

          // ── Password field ────────────────────────────
          _AuthTextField(
            controller: _passwordCtrl,
            hint: 'Password',
            prefixIcon: Icons.lock_outline_rounded,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _login(),
            suffixWidget: GestureDetector(
              onTap: () => setState(() => _obscurePassword = !_obscurePassword),
              child: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 18,
                color: _textSecondary,
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Password is required';
              if (v.length < 6) return 'Minimum 6 characters';
              return null;
            },
          ).animate(delay: 260.ms).fadeIn(),

          const SizedBox(height: 10),

          // ── Remember me + Forgot ──────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 20, height: 20,
                    child: Checkbox(
                      value: _rememberMe,
                      onChanged: (v) => setState(() => _rememberMe = v ?? false),
                      activeColor: _teal,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4)),
                      side: const BorderSide(color: _borderColor, width: 1.5),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text('Remember Me',
                      style: TextStyle(fontSize: 12, color: _textSecondary)),
                ],
              ),
              GestureDetector(
                onTap: () => context.push(AppRoutes.forgotPassword),
                child: const Text('Forgot Password?',
                    style: TextStyle(
                        fontSize: 12, color: _teal, fontWeight: FontWeight.w600)),
              ),
            ],
          ).animate(delay: 300.ms).fadeIn(),

          const SizedBox(height: 16),

          // ── Login button ──────────────────────────────
          _TealButton(
            label: 'Login',
            isLoading: _isLoading,
            onPressed: _login,
          ).animate(delay: 340.ms).fadeIn(),

          const SizedBox(height: 12),

          // ── Divider ───────────────────────────────────
          Row(children: [
            Expanded(child: Divider(color: Colors.grey[200])),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('Or Continue With',
                  style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[400],
                      fontWeight: FontWeight.w500)),
            ),
            Expanded(child: Divider(color: Colors.grey[200])),
          ]).animate(delay: 380.ms).fadeIn(),

          const SizedBox(height: 12),

          // ── Social buttons ────────────────────────────
          Row(
            children: [
              Expanded(
                child: _SocialButton(
                  label: 'Apple',
                  icon: const FaIcon(FontAwesomeIcons.apple, size: 18, color: Colors.white),
                  isDark: true,
                  onTap: () {},
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SocialButton(
                  label: 'Google',
                  icon: _GoogleLogo(),
                  isDark: false,
                  onTap: _googleLogin,
                ),
              ),
            ],
          ).animate(delay: 420.ms).fadeIn(),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Shared widgets
// ─────────────────────────────────────────────────────────────

class _Circle extends StatelessWidget {
  final double size;
  final Color color;
  const _Circle(this.size, this.color);
  @override
  Widget build(BuildContext context) => Container(
        width: size, height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      );
}

class _PhoneMockup extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110, height: 95,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
      ),
      padding: const EdgeInsets.all(9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 5, width: 55,
              decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(3))),
          const SizedBox(height: 4),
          Container(height: 4, width: 38,
              decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(3))),
          const SizedBox(height: 8),
          Container(
            height: 22,
            decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6)),
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(children: [
              const Icon(Icons.mail_outline_rounded, color: Colors.white70, size: 11),
              const SizedBox(width: 4),
              Container(height: 4, width: 44,
                  decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(3))),
            ]),
          ),
          const SizedBox(height: 5),
          Container(
            height: 22,
            decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6)),
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(children: [
              const Icon(Icons.lock_outline_rounded, color: Colors.white70, size: 11),
              const SizedBox(width: 4),
              Container(height: 4, width: 36,
                  decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(3))),
            ]),
          ),
        ],
      ),
    );
  }
}

// ── Auth Text Field ───────────────────────────────────────────
class _AuthTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final IconData prefixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final void Function(String)? onSubmitted;
  final Widget? suffixWidget;

  const _AuthTextField({
    required this.controller,
    required this.hint,
    required this.prefixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction,
    this.validator,
    this.onSubmitted,
    this.suffixWidget,
  });

  @override
  State<_AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<_AuthTextField> {
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
        style: const TextStyle(fontSize: 14, color: _dark, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: const TextStyle(color: _textSecondary, fontSize: 14),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 14, right: 10),
            child: Icon(widget.prefixIcon, size: 19,
                color: _focused ? _teal : _textSecondary),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
          suffixIcon: widget.suffixWidget != null
              ? Padding(padding: const EdgeInsets.only(right: 12), child: widget.suffixWidget)
              : null,
          suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
          filled: true,
          fillColor: _focused ? const Color(0xFFF0FFFE) : const Color(0xFFF8FAFC),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(50),
              borderSide: const BorderSide(color: _borderColor, width: 1)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(50),
              borderSide: const BorderSide(color: _teal, width: 1.5)),
          errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(50),
              borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1)),
          focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(50),
              borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5)),
          border: InputBorder.none,
          errorStyle: const TextStyle(fontSize: 11, color: Color(0xFFEF4444)),
        ),
      ),
    );
  }
}

// ── Teal Button ───────────────────────────────────────────────
class _TealButton extends StatefulWidget {
  final String label;
  final bool isLoading;
  final VoidCallback onPressed;
  const _TealButton({required this.label, required this.isLoading, required this.onPressed});
  @override
  State<_TealButton> createState() => _TealButtonState();
}

class _TealButtonState extends State<_TealButton> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); if (!widget.isLoading) widget.onPressed(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 80),
        child: Container(
          height: 50,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _pressed
                  ? [const Color(0xFF0B8E99), const Color(0xFF0AABB8)]
                  : [_teal, _tealLight],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(50),
            boxShadow: _pressed ? [] : [
              BoxShadow(color: _teal.withValues(alpha: 0.35), blurRadius: 14, offset: const Offset(0, 5)),
            ],
          ),
          child: Center(
            child: widget.isLoading
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                : Text(widget.label,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 15,
                        fontWeight: FontWeight.w700, letterSpacing: 0.3)),
          ),
        ),
      ),
    );
  }
}

// ── Google Logo (multicolor inline SVG) ──────────────────────
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
      SvgPicture.string(_svg, width: 20, height: 20);
}

// ── Social Button ─────────────────────────────────────────────
class _SocialButton extends StatelessWidget {
  final String label;
  final Widget icon;
  final bool isDark;
  final VoidCallback onTap;
  const _SocialButton({required this.label, required this.icon, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: isDark ? _dark : Colors.white,
          borderRadius: BorderRadius.circular(50),
          border: isDark ? null : Border.all(color: _borderColor, width: 1),
          boxShadow: isDark
              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 8, offset: const Offset(0, 2))]
              : [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    color: isDark ? Colors.white : _dark,
                    fontSize: 14, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
