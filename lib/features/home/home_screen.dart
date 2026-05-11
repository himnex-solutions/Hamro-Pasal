import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hamro_pasal/core/router/app_router.dart';

/// Simple placeholder for the unused /home route
/// (Shell routes start at /home/dashboard)
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.go(AppRoutes.dashboard);
    });
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
