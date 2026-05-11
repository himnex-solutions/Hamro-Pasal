import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hamro_pasal/core/router/app_router.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Redirect to login — onboarding can be added later
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.go(AppRoutes.login);
    });
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
