import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hamro_pasal/core/router/app_router.dart';
import 'package:hamro_pasal/core/theme/app_theme.dart';
import 'package:hamro_pasal/core/theme/theme_provider.dart';
import 'package:hamro_pasal/core/widgets/app_snackbar.dart';
import 'package:hamro_pasal/core/providers/profile_mode_provider.dart';
import 'package:hamro_pasal/features/auth/presentation/providers/auth_provider.dart';
import 'package:hamro_pasal/features/settings/presentation/screens/profile_edit_screen.dart';
import 'package:hamro_pasal/features/settings/presentation/screens/business_profile_edit_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile section
          const _SectionHeader('Account'),
          _SettingsTile(
            icon: Icons.person_outline,
            title: 'Profile',
            subtitle: 'Edit your personal information',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const ProfileEditScreen(),
              ),
            ),
          ),
          _SettingsTile(
            icon: Icons.store_outlined,
            title: 'Business Profile',
            subtitle: 'Edit business name, logo, address',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const BusinessProfileEditScreen(),
              ),
            ),
          ),
          const _SwitchProfileTile(),

          const SizedBox(height: 20),
          const _SectionHeader('Preferences'),
          const _ThemeToggleTile(),
          _SettingsTile(
            icon: Icons.language_outlined,
            title: 'Language',
            subtitle: 'English (Nepali coming soon)',
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.currency_rupee_outlined,
            title: 'Currency',
            subtitle: 'NPR — Nepalese Rupee',
            onTap: () {},
          ),

          const SizedBox(height: 20),
          const _SectionHeader('Subscription'),
          _SettingsTile(
            icon: Icons.workspace_premium_outlined,
            title: 'Manage Subscription',
            subtitle: 'View plans & payment history',
            color: AppTheme.primaryColor,
            onTap: () => context.push(AppRoutes.subscription),
          ),

          const SizedBox(height: 20),
          const _SectionHeader('Data & Sync'),
          _SettingsTile(
            icon: Icons.sync_outlined,
            title: 'Sync Now',
            subtitle: 'Manually sync offline data',
            onTap: () => AppSnackbar.show(context, 'Sync started...'),
          ),
          _SettingsTile(
            icon: Icons.backup_outlined,
            title: 'Backup Data',
            subtitle: 'Export all your business data',
            onTap: () {},
          ),

          const SizedBox(height: 20),
          const _SectionHeader('Support'),
          _SettingsTile(
            icon: Icons.help_outline_rounded,
            title: 'Help & FAQ',
            subtitle: 'Get help with Hamro Pasal',
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.feedback_outlined,
            title: 'Send Feedback',
            subtitle: 'Help us improve the app',
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.description_outlined,
            title: 'Terms of Service',
            onTap: () {},
          ),

          const SizedBox(height: 24),
          // App version
          Center(
            child: Text(
              'Hamro Pasal v1.0.0\nMade with ❤️ for Nepal 🇳🇵',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),

          // Sign out
          OutlinedButton.icon(
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Sign Out'),
                  content: const Text('Are you sure you want to sign out?'),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Sign Out'),
                    ),
                  ],
                ),
              );
              if (confirmed == true) {
                await ref.read(authProvider.notifier).signOut();
                if (context.mounted) context.go(AppRoutes.login);
              }
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.errorColor,
              side: const BorderSide(color: AppTheme.errorColor),
              minimumSize: const Size(double.infinity, 48),
            ),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Sign Out'),
          ).animate(delay: 100.ms).fadeIn(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppTheme.primaryColor,
              letterSpacing: 0.5,
            ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Color? color;
  const _SettingsTile({required this.icon, required this.title, this.subtitle, this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: (color ?? AppTheme.primaryColor).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color ?? AppTheme.lightTextSecondary, size: 20),
        ),
        title: Text(title, style: Theme.of(context).textTheme.titleMedium),
        subtitle: subtitle != null
            ? Text(subtitle!, style: Theme.of(context).textTheme.bodySmall)
            : null,
        trailing: const Icon(Icons.chevron_right, color: AppTheme.lightTextHint),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

// ── Switch Profile Tile ─────────────────────────────────────
class _SwitchProfileTile extends ConsumerWidget {
  const _SwitchProfileTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(profileModeProvider);
    final isPersonal = mode == ProfileMode.personal;
    final accentColor = isPersonal
        ? const Color(0xFF8E44AD)  // purple for personal
        : AppTheme.primaryColor;   // brand green for business

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          ref.read(profileModeProvider.notifier).toggle();
          AppSnackbar.show(
            context,
            isPersonal
                ? '🏢 Switched to Business Mode'
                : '👤 Switched to Personal Mode',
            isSuccess: true,
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Animated icon container
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Icon(
                    isPersonal
                        ? Icons.person_rounded
                        : Icons.store_rounded,
                    key: ValueKey(isPersonal),
                    color: accentColor,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Switch Profile',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: Text(
                        isPersonal
                            ? 'Currently: Personal View'
                            : 'Currently: Business View',
                        key: ValueKey(isPersonal),
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: accentColor),
                      ),
                    ),
                  ],
                ),
              ),
              // Animated segmented toggle
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 32,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: accentColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ModeChip(
                      label: 'Personal',
                      icon: Icons.person_outline,
                      isActive: isPersonal,
                      activeColor: const Color(0xFF8E44AD),
                    ),
                    _ModeChip(
                      label: 'Business',
                      icon: Icons.store_outlined,
                      isActive: !isPersonal,
                      activeColor: AppTheme.primaryColor,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final Color activeColor;
  const _ModeChip({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? activeColor : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 13,
              color: isActive ? Colors.white : AppTheme.lightTextHint),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight:
                  isActive ? FontWeight.w700 : FontWeight.normal,
              color: isActive ? Colors.white : AppTheme.lightTextHint,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Theme Toggle Tile ─────────────────────────────────────────
class _ThemeToggleTile extends ConsumerWidget {
  const _ThemeToggleTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            themeMode == ThemeMode.dark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
            color: AppTheme.lightTextSecondary, size: 20,
          ),
        ),
        title: const Text('Dark Mode'),
        subtitle: Text(themeMode == ThemeMode.dark ? 'On' : 'Off'),
        trailing: Switch(
          value: themeMode == ThemeMode.dark,
          onChanged: (_) => ref.read(themeModeProvider.notifier).toggleTheme(),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
