import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hamro_pasal/core/router/app_router.dart';
import 'package:hamro_pasal/core/theme/app_theme.dart';
import 'package:hamro_pasal/core/widgets/app_snackbar.dart';
import 'package:hamro_pasal/features/auth/presentation/providers/auth_provider.dart';

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
    final size = MediaQuery.of(context).size;
    final isWide = size.width >= 960;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: isWide ? _buildDesktopLayout() : _buildMobileLayout(),
    );
  }

  // ── Desktop: Split panel ──────────────────────────────────────
  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Left: Dark brand panel
        Expanded(
          flex: 5,
          child: _BrandPanel(),
        ),
        // Right: Form panel
        Expanded(
          flex: 4,
          child: Container(
            color: Colors.white,
            child: Center(
              child: SizedBox(
                width: 400,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 48),
                  child: _buildForm(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Mobile: Clean card ────────────────────────────────────────
  Widget _buildMobileLayout() {
    return Container(
      color: const Color(0xFFF1F5F9),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Compact brand bar
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
                decoration: const BoxDecoration(
                  color: Color(0xFF0F172A),
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.store_rounded, color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 12),
                        const Text('Hamro Pasal',
                          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                      ],
                    ).animate().fadeIn().slideX(begin: -0.1, end: 0),
                    const SizedBox(height: 20),
                    const Text('Welcome back',
                      style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800, height: 1.1)),
                    const SizedBox(height: 6),
                    Text('Sign in to manage your business',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 14)),
                  ],
                ).animate().fadeIn(delay: 100.ms),
              ),
              // Form card
              Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 24, offset: const Offset(0, 4)),
                  ],
                ),
                child: _buildForm(),
              ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.05, end: 0),
            ],
          ),
        ),
      ),
    );
  }

  // ── Shared form ───────────────────────────────────────────────
  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header (desktop only inline, mobile in panel)
          if (MediaQuery.of(context).size.width >= 960) ...[
            const Text('Sign in to your account',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A), letterSpacing: -0.3)),
            const SizedBox(height: 6),
            Text('Enter your credentials to continue',
              style: TextStyle(fontSize: 14, color: Colors.grey[500])),
            const SizedBox(height: 32),
          ],

          // Email
          _FieldLabel('Email address'),
          const SizedBox(height: 6),
          _FormField(
            controller: _emailCtrl,
            hint: 'you@business.com',
            icon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Email is required';
              if (!v.contains('@')) return 'Enter a valid email';
              return null;
            },
          ).animate(delay: 150.ms).fadeIn(),

          const SizedBox(height: 18),

          // Password
          _FieldLabel('Password'),
          const SizedBox(height: 6),
          _FormField(
            controller: _passwordCtrl,
            hint: '••••••••',
            icon: Icons.lock_outline_rounded,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _login(),
            suffixIcon: GestureDetector(
              onTap: () => setState(() => _obscurePassword = !_obscurePassword),
              child: Icon(
                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 18,
                color: Colors.grey[400],
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Password is required';
              if (v.length < 6) return 'Minimum 6 characters';
              return null;
            },
          ).animate(delay: 200.ms).fadeIn(),

          const SizedBox(height: 10),

          // Forgot password
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () => context.push(AppRoutes.forgotPassword),
              child: Text('Forgot password?',
                style: TextStyle(fontSize: 13, color: AppTheme.primaryColor, fontWeight: FontWeight.w600)),
            ),
          ),

          const SizedBox(height: 24),

          // Primary CTA
          _PrimaryButton(
            label: 'Sign in',
            isLoading: _isLoading,
            onPressed: _login,
          ).animate(delay: 250.ms).fadeIn(),

          const SizedBox(height: 16),

          // Divider
          Row(children: [
            Expanded(child: Divider(color: Colors.grey[200])),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Text('or', style: TextStyle(fontSize: 12, color: Colors.grey[400], fontWeight: FontWeight.w500)),
            ),
            Expanded(child: Divider(color: Colors.grey[200])),
          ]).animate(delay: 300.ms).fadeIn(),

          const SizedBox(height: 16),

          // Google sign-in
          _GoogleButton(isLoading: _isLoading, onPressed: _googleLogin)
              .animate(delay: 350.ms).fadeIn(),

          const SizedBox(height: 28),

          // Sign up
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Don't have an account? ",
                    style: TextStyle(fontSize: 13, color: Colors.grey[500])),
                GestureDetector(
                  onTap: () => context.push(AppRoutes.signup),
                  child: Text('Create account',
                      style: TextStyle(fontSize: 13, color: AppTheme.primaryColor, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ).animate(delay: 400.ms).fadeIn(),
        ],
      ),
    );
  }
}

// ── Brand Panel (Desktop Left) ────────────────────────────────
class _BrandPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Subtle grid pattern
          CustomPaint(painter: _GridPainter(), size: Size.infinite),
          // Accent orb
          Positioned(bottom: -80, right: -80,
            child: Container(width: 400, height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryColor.withValues(alpha: 0.06),
              ))),
          Positioned(top: 60, left: -60,
            child: Container(width: 200, height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF6366F1).withValues(alpha: 0.05),
              ))),
          // Content
          Padding(
            padding: const EdgeInsets.all(52),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo
                Row(children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.store_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Text('Hamro Pasal',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                ]).animate().fadeIn().slideX(begin: -0.1, end: 0),

                const Spacer(),

                // Headline
                const Text('Business\nManagement\nSimplified.',
                  style: TextStyle(color: Colors.white, fontSize: 44,
                      fontWeight: FontWeight.w800, height: 1.1, letterSpacing: -1)),
                const SizedBox(height: 20),
                Text('Track sales, expenses, inventory\nand parties — all in one place.',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 15, height: 1.7)),
                const SizedBox(height: 40),

                // Feature pills
                Wrap(
                  spacing: 10, runSpacing: 10,
                  children: const [
                    _FeaturePill('📊  Sales Analytics'),
                    _FeaturePill('📦  Inventory'),
                    _FeaturePill('🧾  Invoicing'),
                    _FeaturePill('👥  Party Ledger'),
                  ],
                ),
                const Spacer(),

                // Social proof
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Container(width: 8, height: 8,
                        decoration: const BoxDecoration(color: Color(0xFF22C55E), shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Text('Made for Nepali businesses',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 12, fontWeight: FontWeight.w500)),
                    ]),
                  ),
                ]),
                const SizedBox(height: 8),
              ],
            ),
          ).animate().fadeIn(delay: 100.ms),
        ],
      ),
    );
  }
}

class _FeaturePill extends StatelessWidget {
  final String label;
  const _FeaturePill(this.label);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.07),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
    ),
    child: Text(label,
      style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12, fontWeight: FontWeight.w500)),
  );
}

// ── Grid Painter ──────────────────────────────────────────────
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.025)
      ..strokeWidth = 1;
    const step = 48.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }
  @override
  bool shouldRepaint(_) => false;
}

// ── Field Label ───────────────────────────────────────────────
class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151)));
}

// ── Form Field ────────────────────────────────────────────────
class _FormField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final void Function(String)? onSubmitted;
  final Widget? suffixIcon;

  const _FormField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction,
    this.validator,
    this.onSubmitted,
    this.suffixIcon,
  });

  @override
  State<_FormField> createState() => _FormFieldState();
}

class _FormFieldState extends State<_FormField> {
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
        style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A), fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 14, right: 10),
            child: Icon(widget.icon,
              size: 18,
              color: _focused ? AppTheme.primaryColor : Colors.grey[400]),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
          suffixIcon: widget.suffixIcon != null
              ? Padding(padding: const EdgeInsets.only(right: 12), child: widget.suffixIcon)
              : null,
          suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
          filled: true,
          fillColor: _focused ? const Color(0xFFF8FAFF) : const Color(0xFFF9FAFB),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: AppTheme.primaryColor, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
          ),
          border: InputBorder.none,
          errorStyle: const TextStyle(fontSize: 12, color: Color(0xFFEF4444)),
        ),
      ),
    );
  }
}

// ── Primary Button ────────────────────────────────────────────
class _PrimaryButton extends StatefulWidget {
  final String label;
  final bool isLoading;
  final VoidCallback onPressed;
  const _PrimaryButton({required this.label, required this.isLoading, required this.onPressed});
  @override
  State<_PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<_PrimaryButton> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); if (!widget.isLoading) widget.onPressed(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 80),
        child: Container(
          height: 48,
          width: double.infinity,
          decoration: BoxDecoration(
            color: _pressed
                ? const Color(0xFF1557B0)
                : AppTheme.primaryColor,
            borderRadius: BorderRadius.circular(10),
            boxShadow: _pressed ? [] : [
              BoxShadow(
                color: AppTheme.primaryColor.withValues(alpha: 0.30),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: widget.isLoading
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(widget.label,
                    style: const TextStyle(color: Colors.white, fontSize: 14,
                        fontWeight: FontWeight.w700, letterSpacing: 0.2)),
          ),
        ),
      ),
    );
  }
}

// ── Google Button ─────────────────────────────────────────────
class _GoogleButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;
  const _GoogleButton({required this.isLoading, required this.onPressed});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onPressed,
      child: Container(
        height: 48,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Google G icon drawn manually
            Container(
              width: 18, height: 18,
              decoration: const BoxDecoration(color: Color(0xFF4285F4), shape: BoxShape.circle),
              child: const Center(
                child: Text('G', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)),
              ),
            ),
            const SizedBox(width: 10),
            const Text('Continue with Google',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
          ],
        ),
      ),
    );
  }
}
