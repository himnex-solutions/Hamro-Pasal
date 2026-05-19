import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hamro_pasal/core/router/app_router.dart';
import 'package:hamro_pasal/features/auth/presentation/providers/auth_provider.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _gradientController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.94, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _navigate();
  }

  @override
  void dispose() {
    _gradientController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _navigate() async {
    // Wait for the minimum splash animation duration
    await Future.delayed(const Duration(milliseconds: 2800));
    if (!mounted) return;

    // Wait until auth initialization completes
    var authState = ref.read(authProvider);
    while (authState.status == AuthStatus.initial) {
      if (!mounted) return;
      await Future.delayed(const Duration(milliseconds: 100));
      authState = ref.read(authProvider);
    }

    if (!mounted) return;

    switch (authState.status) {
      case AuthStatus.authenticated:
        context.go(AppRoutes.dashboard);
        break;
      case AuthStatus.needsBusinessSetup:
        context.go(AppRoutes.businessSetup);
        break;
      case AuthStatus.needsOtpVerification:
        context.go(AppRoutes.login);
        break;
      case AuthStatus.unauthenticated:
      case AuthStatus.initial: // Fallback, though should no longer occur
        context.go(AppRoutes.onboarding);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _gradientController,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(
                    const Color(0xFF0F172A),
                    const Color(0xFF1E1B4B),
                    _gradientController.value,
                  )!,
                  Color.lerp(
                    const Color(0xFF1A3A6E),
                    const Color(0xFF312E81),
                    _gradientController.value,
                  )!,
                  Color.lerp(
                    const Color(0xFF1E6FD9),
                    const Color(0xFF4338CA),
                    _gradientController.value,
                  )!,
                ],
              ),
            ),
            child: child,
          );
        },
        child: Stack(
          children: [
            // Background decorative orbs — direct Positioned children (no LayoutBuilder)
            Positioned(
                top: -80,
                right: -60,
                child:
                    _Orb(300, const Color(0xFF3B82F6).withValues(alpha: 0.15))),
            Positioned(
                bottom: -100,
                left: -80,
                child:
                    _Orb(360, const Color(0xFF6366F1).withValues(alpha: 0.12))),
            Positioned(
                top: MediaQuery.sizeOf(context).height * 0.4,
                right: -40,
                child:
                    _Orb(200, const Color(0xFF06B6D4).withValues(alpha: 0.08))),
            Positioned(
                top: MediaQuery.sizeOf(context).height * 0.2,
                left: -30,
                child:
                    _Orb(180, const Color(0xFF8B5CF6).withValues(alpha: 0.10))),

            // Main content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Pulsing glow logo
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation.value,
                        child: child,
                      );
                    },
                    child: Container(
                      width: 112,
                      height: 112,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(32),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF60A5FA), Color(0xFF1E6FD9)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFF1E6FD9).withValues(alpha: 0.55),
                            blurRadius: 45,
                            spreadRadius: 8,
                          ),
                          BoxShadow(
                            color:
                                const Color(0xFF6366F1).withValues(alpha: 0.35),
                            blurRadius: 80,
                            spreadRadius: 15,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.store_rounded,
                        size: 58,
                        color: Colors.white,
                      ),
                    ),
                  )
                      .animate()
                      .scale(
                          duration: 700.ms,
                          curve: Curves.elasticOut,
                          begin: const Offset(0.3, 0.3))
                      .fadeIn(duration: 500.ms),

                  const SizedBox(height: 32),

                  // App name with gradient text
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Colors.white, Color(0xFFBAE6FD)],
                    ).createShader(bounds),
                    child: const Text(
                      'Hamro Pasal',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      ),
                    ),
                  )
                      .animate(delay: 300.ms)
                      .fadeIn(duration: 600.ms)
                      .slideY(begin: 0.4, end: 0),

                  const SizedBox(height: 10),

                  Text(
                    'Your Business, Simplified.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 15,
                      letterSpacing: 0.5,
                    ),
                  ).animate(delay: 500.ms).fadeIn(duration: 600.ms),

                  const SizedBox(height: 80),

                  // Premium loading dots
                  LoadingAnimationWidget.staggeredDotsWave(
                    color: Colors.white.withValues(alpha: 0.85),
                    size: 38,
                  ).animate(delay: 900.ms).fadeIn(duration: 500.ms),
                ],
              ),
            ),

            // Bottom tagline
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Made with ',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.4),
                          letterSpacing: 1)),
                  const Icon(Icons.favorite, color: Colors.red, size: 14),
                  Text(' in Nepal',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.4),
                          letterSpacing: 1)),
                ],
              ).animate(delay: 1200.ms).fadeIn(),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Orb background circle ─────────────────────────────────────
class _Orb extends StatelessWidget {
  final double size;
  final Color color;
  const _Orb(this.size, this.color);

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      );
}
