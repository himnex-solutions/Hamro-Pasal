import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_saoji/core/router/app_router.dart';
import 'package:smart_saoji/core/services/app_lock_service.dart';
import 'package:smart_saoji/core/theme/app_theme.dart';
import 'package:smart_saoji/core/widgets/poly_mesh_background.dart';
import 'package:smart_saoji/features/auth/presentation/providers/auth_provider.dart';
import 'package:smart_saoji/features/settings/presentation/screens/pin_lock_screen.dart';
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
        final hasPinLock = await AppLockService.isEnabled();
        if (hasPinLock) {
          if (!mounted) return;
          final unlocked = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (context) => const PinLockScreen(),
            ),
          );
          if (unlocked == true && mounted) {
            context.go(AppRoutes.dashboard);
          }
        } else {
          if (mounted) {
            context.go(AppRoutes.dashboard);
          }
        }
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
      backgroundColor: Colors.white,
      body: AnimatedBuilder(
        animation: _gradientController,
        builder: (context, child) {
          final animatedAccent = Color.lerp(
            AppTheme.primaryColor,
            AppTheme.primaryLight,
            _gradientController.value,
          );
          return PolyMeshBackground(
            isLight: true,
            accentColor: animatedAccent,
            child: child,
          );
        },
        child: Stack(
          children: [
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
                    child: SizedBox(
                      width: 300,
                      height: 87,
                      child: Image.asset(
                        'assets/images/smart_saoji_logo.png',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 112,
                          height: 112,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(32),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF2537D5), Color(0xFF6B58F5)],
                            ),
                          ),
                          child: const Icon(
                            Icons.store_rounded,
                            size: 58,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  )
                      .animate()
                      .scale(
                          duration: 700.ms,
                          curve: Curves.elasticOut,
                          begin: const Offset(0.3, 0.3))
                      .fadeIn(duration: 500.ms),

                  const SizedBox(height: 18),

                  const Text(
                    'Your Business, Simplified.',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 15.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ).animate(delay: 500.ms).fadeIn(duration: 600.ms),

                  const SizedBox(height: 80),

                  // Premium loading dots
                  LoadingAnimationWidget.staggeredDotsWave(
                    color: AppTheme.primaryColor,
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
              child: Text(
                'Himnex Solutions Pvt. Ltd.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF94A3B8),
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.2,
                    ),
              ).animate(delay: 1200.ms).fadeIn(),
            ),
          ],
        ),
      ),
    );
  }
}
