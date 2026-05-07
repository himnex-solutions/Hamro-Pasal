import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/supabase_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/providers/profile_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _scaleAnim = Tween<double>(begin: 0.7, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _ctrl.forward();

    // Wait for animation then route
    Future.delayed(const Duration(milliseconds: 1500), _checkAuthAndRoute);
  }

  Future<void> _checkAuthAndRoute() async {
    if (!mounted) {
      return;
    }

    final user = ref.read(currentUserProvider);
    if (user == null) {
      context.go(AppConstants.routeSelectProfile);
      return;
    }

    // Check if email is verified first
    final userId = SupabaseService.instance.currentUserId;
    if (userId != null) {
      final profileJson = await SupabaseService.instance.getUserProfile(userId);
      final emailVerified = profileJson?['email_verified'] as bool? ?? false;

      if (!emailVerified && mounted) {
        context.go(
          AppConstants.routeEmailVerification,
          extra: user.email ?? '',
        );
        return;
      }
    }

    // Wait for active profile to load if it's not ready.
    await ref.read(activeProfileProvider.notifier).loadProfile();
    final activeProfileState = ref.read(activeProfileProvider).valueOrNull;

    if (!mounted) {
      return;
    }

    if (activeProfileState != null) {
      if (activeProfileState.activeProfileType == 'business') {
        context.go(AppConstants.routeDashboard);
      } else {
        context.go(AppConstants.routePersonalDashboard);
      }
    } else {
      // If no active profile is set, let's check user profile
      await ref.read(userProfileProvider.notifier).loadProfile();
      final userProfileState = ref.read(userProfileProvider).valueOrNull;
      if (!mounted) {
        return;
      }

      if (userProfileState != null) {
        if (userProfileState.profileType == 'business') {
          context.go(AppConstants.routeDashboard);
        } else {
          context.go(AppConstants.routePersonalDashboard);
        }
      } else {
        // Logged in but no profile at all? Something went wrong during signup. Let's send to select profile.
        context.go(AppConstants.routeSelectProfile);
      }
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, Color(0xFF0D2F8A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Logo
              FadeTransition(
                opacity: _fadeAnim,
                child: ScaleTransition(
                  scale: _scaleAnim,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3), width: 2),
                    ),
                    child: const Icon(
                      Icons.storefront_rounded,
                      size: 72,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              // App Name
              FadeTransition(
                opacity: _fadeAnim,
                child: Column(
                  children: [
                    Text(
                      AppConstants.appName,
                      style: Theme.of(context)
                          .textTheme
                          .displaySmall
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppConstants.appTagline,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.75),
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 64),
              // Loading indicator
              FadeTransition(
                opacity: _fadeAnim,
                child: SizedBox(
                  width: 200,
                  child: LinearProgressIndicator(
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.white),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
