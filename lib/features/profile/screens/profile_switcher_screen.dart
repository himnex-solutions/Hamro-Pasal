import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/profile_provider.dart';
import '../../auth/models/active_profile.dart';
import '../../../core/services/supabase_service.dart';

class ProfileSwitcherScreen extends ConsumerWidget {
  const ProfileSwitcherScreen({super.key});

  Future<void> _switchProfile(BuildContext context, WidgetRef ref, String profileType) async {
    final userId = SupabaseService.instance.currentUserId;
    if (userId == null) {
      return;
    }
    
    // Save to active profiles
    final activeProfile = ActiveProfile(
      id: '',
      userId: userId,
      activeProfileId: '', // Ideally we store the ID of the selected profile
      activeProfileType: profileType,
      updatedAt: DateTime.now(),
    );
    await ref.read(activeProfileProvider.notifier).saveProfile(activeProfile);
    
    if (context.mounted) {
      if (profileType == 'business') {
        context.go(AppConstants.routeDashboard);
      } else {
        context.go(AppConstants.routePersonalDashboard);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeProfileState = ref.watch(activeProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Profiles'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppConstants.routeDashboard);
            }
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Switch Profile',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Select the profile you want to use right now.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 32),
              
              activeProfileState.when(
                data: (activeProfile) {
                  final currentType = activeProfile?.activeProfileType ?? 'business'; // default
                  
                  return Column(
                    children: [
                      _ProfileCard(
                        title: 'Business Management',
                        subtitle: 'Manage accounting and inventory',
                        iconData: Icons.storefront_rounded,
                        isActive: currentType == 'business',
                        onTap: () => _switchProfile(context, ref, 'business'),
                      ),
                      const SizedBox(height: 16),
                      _ProfileCard(
                        title: 'Personal Finance',
                        subtitle: 'Track personal expenses',
                        iconData: Icons.person_rounded,
                        isActive: currentType == 'personal',
                        onTap: () => _switchProfile(context, ref, 'personal'),
                      ),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => Text('Error: $e'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData iconData;
  final bool isActive;
  final VoidCallback onTap;

  const _ProfileCard({
    required this.title,
    required this.subtitle,
    required this.iconData,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isActive ? AppColors.primary : Colors.grey.withValues(alpha: 0.3),
            width: isActive ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
          color: isActive ? AppColors.primary.withValues(alpha: 0.05) : Colors.transparent,
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: isActive ? AppColors.primary : Colors.grey.withValues(alpha: 0.2),
              radius: 24,
              child: Icon(
                iconData,
                color: isActive ? Colors.white : Colors.grey[700],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isActive ? AppColors.primary : null,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
            if (isActive)
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.primary,
              ),
          ],
        ),
      ),
    );
  }
}
