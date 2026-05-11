import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hamro_pasal/core/router/app_router.dart';
import 'package:hamro_pasal/core/theme/app_theme.dart';
import 'package:hamro_pasal/features/auth/presentation/providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    // Wait for animation
    await Future.delayed(const Duration(milliseconds: 2200));
    if (!mounted) return;

    final authState = ref.read(authProvider);
    switch (authState.status) {
      case AuthStatus.authenticated:
        context.go(AppRoutes.dashboard);
        break;
      case AuthStatus.needsBusinessSetup:
        context.go(AppRoutes.businessSetup);
        break;
      case AuthStatus.unauthenticated:
      case AuthStatus.initial:
        context.go(AppRoutes.login);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Icon(Icons.store_rounded, size: 56, color: Colors.white),
            )
            .animate()
            .scale(duration: 600.ms, curve: Curves.elasticOut)
            .fadeIn(duration: 400.ms),

            const SizedBox(height: 24),

            const Text('Hamro Pasal',
                style: TextStyle(
                    color: Colors.white, fontSize: 32,
                    fontWeight: FontWeight.w800, letterSpacing: 1))
                .animate(delay: 300.ms).fadeIn().slideY(begin: 0.3, end: 0),

            const SizedBox(height: 8),

            Text('Your Business, Simplified.',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8), fontSize: 15))
                .animate(delay: 500.ms).fadeIn(),

            const SizedBox(height: 60),

            SizedBox(
              width: 32, height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ).animate(delay: 1000.ms).fadeIn(),
          ],
        ),
      ),
    );
  }
}
