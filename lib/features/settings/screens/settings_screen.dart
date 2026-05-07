import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/auth/providers/profile_provider.dart';
import '../../../features/subscription/providers/subscription_provider.dart';
import '../../../features/subscription/models/subscription.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeProfile = ref.watch(activeProfileProvider).valueOrNull;
    final isBusiness = activeProfile?.activeProfileType != 'personal';

    final businessProfile = ref.watch(businessProfileProvider).valueOrNull;
    final personalProfile = ref.watch(personalProfileProvider).valueOrNull;
    final sub = ref.watch(subscriptionProvider).valueOrNull;
    final themeMode = ref.watch(themeModeProvider);

    final currentProfileName = isBusiness
        ? (businessProfile?.businessName ?? 'Hamro Pasal')
        : (personalProfile?.fullName ?? 'Personal Profile');

    final currentProfilePhone = isBusiness
        ? (businessProfile?.phone ?? '')
        : (personalProfile?.phone ?? '');

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // Profile card
          _ProfileCard(
            name: currentProfileName,
            phone: currentProfilePhone,
            sub: sub,
            isBusiness: isBusiness,
          ),
          const SizedBox(height: 8),

          // Profile Management
          const _SectionHeader('Profile Management'),
          _SettingsTile(
            icon: Icons.manage_accounts_rounded,
            iconColor: AppColors.primary,
            title: 'Switch Profile',
            subtitle: 'Change between Business and Personal',
            onTap: () => context.push(AppConstants.routeProfileSwitcher),
            showArrow: true,
          ),
          if (isBusiness)
            _SettingsTile(
              icon: Icons.storefront_rounded,
              iconColor: AppColors.primary,
              title: 'Edit Business Details',
              onTap: () => context.push(AppConstants.routeProfileSetup),
              showArrow: true,
            )
          else
            _SettingsTile(
              icon: Icons.person_outline_rounded,
              iconColor: AppColors.primary,
              title: 'Edit Personal Profile',
              onTap: () =>
                  context.push(AppConstants.routeUpdatePersonalProfile),
              showArrow: true,
            ),

          // Appearance
          const _SectionHeader('Appearance'),
          _SettingsTile(
            icon: Icons.dark_mode_rounded,
            iconColor: AppColors.posColor,
            title: 'Dark Mode',
            trailing: Switch(
              value: themeMode == ThemeMode.dark,
              onChanged: (_) =>
                  ref.read(themeModeProvider.notifier).toggleTheme(),
              activeThumbColor: AppColors.primary,
            ),
          ),

          // Subscription
          const _SectionHeader('Subscription'),
          _SettingsTile(
            icon: Icons.workspace_premium_rounded,
            iconColor: AppColors.accent,
            title: 'Current Plan',
            subtitle: _planLabel(sub),
            onTap: () => context.push(AppConstants.routeSubscription),
            showArrow: true,
          ),
          if (sub != null && (sub.isActive || sub.isTrial))
            _SettingsTile(
              icon: Icons.calendar_today_rounded,
              iconColor: AppColors.success,
              title: 'Valid Until',
              subtitle:
                  '${sub.endDate.day}/${sub.endDate.month}/${sub.endDate.year} (${sub.daysRemaining} days left)',
            ),

          // Shop Settings (Only for Business)
          if (isBusiness) ...[
            const _SectionHeader('Shop Settings'),
            _SettingsTile(
              icon: Icons.print_rounded,
              iconColor: AppColors.inventoryColor,
              title: 'Receipt Settings',
              subtitle: 'Configure receipt format',
              onTap: () {},
              showArrow: true,
            ),
          ],

          // Data
          const _SectionHeader('Data & Backup'),
          _SettingsTile(
            icon: Icons.backup_rounded,
            iconColor: AppColors.suppliersColor,
            title: 'Backup Data',
            subtitle: 'Export to CSV/Excel',
            onTap: () {},
            showArrow: true,
          ),
          _SettingsTile(
            icon: Icons.restore_rounded,
            iconColor: AppColors.reportsColor,
            title: 'Restore Data',
            onTap: () {},
            showArrow: true,
          ),

          // Support
          const _SectionHeader('Support'),
          _SettingsTile(
            icon: Icons.help_outline_rounded,
            iconColor: AppColors.info,
            title: 'Help & FAQ',
            onTap: () {},
            showArrow: true,
          ),
          _SettingsTile(
            icon: Icons.star_rounded,
            iconColor: AppColors.accent,
            title: 'Rate Hamro Pasal',
            onTap: () {},
            showArrow: true,
          ),
          _VersionTile(),

          // Logout
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton.icon(
              onPressed: () => _confirmLogout(context, ref),
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Sign Out'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  String _planLabel(Subscription? sub) {
    if (sub == null) {
      return 'No active plan';
    }
    switch (sub.planType) {
      case SubscriptionPlan.free:
        return 'Free Trial (${sub.daysRemaining} days left)';
      case SubscriptionPlan.monthly:
        return 'Monthly Plan';
      case SubscriptionPlan.sixMonth:
        return '6-Month Plan';
      case SubscriptionPlan.yearly:
        return 'Yearly Plan';
    }
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogCtx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      // Delay by one frame so the dialog close animation fully finishes
      // before GoRouter fires its redirect. Prevents !_debugLocked crash.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(authNotifierProvider.notifier).signOut();
      });
    }
  }
}

class _ProfileCard extends StatelessWidget {
  final String name;
  final String phone;
  final dynamic sub;
  final bool isBusiness;
  const _ProfileCard({
    required this.name,
    required this.phone,
    required this.sub,
    required this.isBusiness,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isBusiness
              ? [AppColors.primary, const Color(0xFF1338B0)]
              : [const Color(0xFF0D47A1), const Color(0xFF1976D2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : 'H',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                if (phone.isNotEmpty)
                  Text(phone,
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 4),
                if (isBusiness && sub != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      sub!.planType == SubscriptionPlan.free
                          ? '🆓 Free Trial'
                          : '⭐ ${sub!.planType.name.toUpperCase()}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: Text(title,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.primary, fontWeight: FontWeight.w700)),
      );
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showArrow;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.showArrow = false,
  });

  @override
  Widget build(BuildContext context) => ListTile(
        onTap: onTap,
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(title,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontWeight: FontWeight.w500)),
        subtitle: subtitle != null
            ? Text(subtitle!,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.textSecondary))
            : null,
        trailing: trailing ??
            (showArrow
                ? const Icon(Icons.chevron_right_rounded,
                    color: AppColors.textHint)
                : null),
      );
}

class _VersionTile extends StatefulWidget {
  @override
  State<_VersionTile> createState() => _VersionTileState();
}

class _VersionTileState extends State<_VersionTile> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted)
        setState(() => _version = '${info.version}+${info.buildNumber}');
    });
  }

  @override
  Widget build(BuildContext context) => _SettingsTile(
        icon: Icons.info_outline_rounded,
        iconColor: AppColors.textSecondary,
        title: 'App Version',
        subtitle: _version.isEmpty ? AppConstants.appVersion : _version,
      );
}
