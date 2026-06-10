import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_saoji/core/l10n/app_strings.dart';
import 'package:smart_saoji/core/providers/locale_provider.dart';
import 'package:smart_saoji/core/router/app_router.dart';
import 'package:smart_saoji/core/theme/app_theme.dart';
import 'package:smart_saoji/core/theme/theme_provider.dart';
import 'package:smart_saoji/core/widgets/app_snackbar.dart';
import 'package:smart_saoji/core/providers/profile_mode_provider.dart';
import 'package:smart_saoji/features/auth/presentation/providers/auth_provider.dart';
import 'package:smart_saoji/features/settings/presentation/screens/profile_edit_screen.dart';
import 'package:smart_saoji/features/settings/presentation/screens/business_profile_edit_screen.dart';
import 'package:smart_saoji/features/settings/presentation/screens/help_faq_screen.dart';
import 'package:smart_saoji/features/settings/presentation/screens/send_feedback_screen.dart';
import 'package:smart_saoji/features/settings/presentation/screens/legal_screens.dart';
import 'package:smart_saoji/core/services/app_lock_service.dart';
import 'package:smart_saoji/features/settings/presentation/screens/pin_lock_screen.dart';
import 'package:smart_saoji/features/subscription/data/services/subscription_manager.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l.settings)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Account ──────────────────────────────────────
          _SectionHeader(l.account),
          _SettingsTile(
            icon: Icons.person_outline,
            title: l.profile,
            subtitle: l.editProfile,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProfileEditScreen()),
            ),
          ),
          _SettingsTile(
            icon: Icons.store_outlined,
            title: l.businessProfile,
            subtitle: l.editBusiness,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => const BusinessProfileEditScreen()),
            ),
          ),
          const _SwitchProfileTile(),

          const SizedBox(height: 20),

          // ── Preferences ───────────────────────────────────
          _SectionHeader(l.preferences),
          const _ThemeToggleTile(),
          const _LanguageTile(), // ← working language picker
          _SettingsTile(
            icon: Icons.receipt_long_outlined,
            title: 'Invoice Customization',
            subtitle: 'Color, prefix, fields & print size settings',
            onTap: () => context.push(AppRoutes.invoiceSettings),
          ),
          _SettingsTile(
            icon: Icons.currency_rupee_outlined,
            title: l.currency2,
            subtitle: l.currencySubtitle,
            onTap: () {},
          ),

          const SizedBox(height: 20),

          // ── Security ──────────────────────────────────────
          const _SectionHeader('Security'),
          const _SecurityAppLockTile(),

          const SizedBox(height: 20),

          // ── Subscription ──────────────────────────────────
          _SectionHeader(l.subscription),
          _SettingsTile(
            icon: Icons.workspace_premium_outlined,
            title: l.manageSubscription,
            subtitle: l.viewPlans,
            color: AppTheme.primaryColor,
            onTap: () {
              final plan = ref.read(subscriptionManagerProvider).planCode;
              if (plan == 'diamond') {
                AppSnackbar.show(
                  context,
                  l.highestPlanMsg,
                  isSuccess: true,
                );
              } else {
                context.push(AppRoutes.subscription);
              }
            },
          ),
          const SizedBox(height: 20),

          // ── Tools ──────────────────────────────────────────
          _SectionHeader(l.tools),
          _SettingsTile(
            icon: Icons.build_outlined,
            title: 'Business Tools',
            subtitle: 'Calculators & Utilities',
            color: AppTheme.primaryColor,
            onTap: () => context.go(AppRoutes.tools),
          ),

          const SizedBox(height: 20),

          // ── Data & Sync ───────────────────────────────────
          _SectionHeader(l.dataSync),
          _SettingsTile(
            icon: Icons.sync_outlined,
            title: l.syncNow,
            subtitle: l.syncSubtitle,
            onTap: () => AppSnackbar.show(context, 'Sync started...'),
          ),
          _SettingsTile(
            icon: Icons.backup_outlined,
            title: l.backupData,
            subtitle: l.backupSubtitle,
            onTap: () {},
          ),

          const SizedBox(height: 20),

          // ── Support ───────────────────────────────────────
          _SectionHeader(l.support),
          _SettingsTile(
            icon: Icons.help_outline_rounded,
            title: l.helpFaq,
            subtitle: l.helpSubtitle,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const HelpFaqScreen()),
            ),
          ),
          _SettingsTile(
            icon: Icons.feedback_outlined,
            title: l.sendFeedback,
            subtitle: l.feedbackSubtitle,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SendFeedbackScreen()),
            ),
          ),
          _SettingsTile(
            icon: Icons.privacy_tip_outlined,
            title: l.privacyPolicy,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
            ),
          ),
          _SettingsTile(
            icon: Icons.description_outlined,
            title: l.termsOfService,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const TermsOfServiceScreen()),
            ),
          ),

          const SizedBox(height: 24),

          Center(
            child: Text(
              l.madeWithLove,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),

          // ── Sign Out ──────────────────────────────────────
          OutlinedButton.icon(
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(

                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  title: Text(
                    l.signOut,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.signOutConfirm,
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.errorColor,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(l.signOut,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.lightTextSecondary,
                                side: BorderSide(
                                    color: AppTheme.lightTextSecondary
                                        .withValues(alpha: 0.4)),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(l.cancel,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w500)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
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
            label: Text(l.signOut),
          ).animate(delay: 100.ms).fadeIn(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ── Language Tile ─────────────────────────────────────────────
class _LanguageTile extends ConsumerWidget {
  const _LanguageTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final currentLocale = ref.watch(localeProvider);
    final isNepali = currentLocale.languageCode == 'ne';
    final subtitle = isNepali ? 'नेपाली' : 'English';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppTheme.darkBorder
                : Colors.white,
            width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showLanguagePicker(context, ref, currentLocale),
          child: ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.language_outlined,
                  color: AppTheme.lightTextSecondary, size: 20),
            ),
            title: Text(l.language,
                style: Theme.of(context).textTheme.titleMedium),
            subtitle:
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            trailing:
                const Icon(Icons.chevron_right, color: AppTheme.lightTextHint),
          ),
        ),
      ),
    );
  }

  Future<void> _showLanguagePicker(
      BuildContext context, WidgetRef ref, Locale currentLocale) async {
    final l = context.l10n;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.selectLanguage),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 0),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _LangOption(
              flag: '🇬🇧',
              label: 'English',
              sublabel: 'English',
              isSelected: currentLocale.languageCode == 'en',
              onTap: () async {
                Navigator.pop(ctx);
                await ref
                    .read(localeProvider.notifier)
                    .setLocale(const Locale('en'));
                if (context.mounted) {
                  AppSnackbar.show(context, '🇬🇧 Language changed to English',
                      isSuccess: true);
                }
              },
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            _LangOption(
              flag: '🇳🇵',
              label: 'नेपाली',
              sublabel: 'Nepali',
              isSelected: currentLocale.languageCode == 'ne',
              onTap: () async {
                Navigator.pop(ctx);
                await ref
                    .read(localeProvider.notifier)
                    .setLocale(const Locale('ne'));
                if (context.mounted) {
                  AppSnackbar.show(context, '🇳🇵 भाषा नेपालीमा परिवर्तन भयो',
                      isSuccess: true);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _LangOption extends StatelessWidget {
  final String flag;
  final String label;
  final String sublabel;
  final bool isSelected;
  final VoidCallback onTap;
  const _LangOption({
    required this.flag,
    required this.label,
    required this.sublabel,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Text(flag, style: const TextStyle(fontSize: 28)),
      title: Text(label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                color: isSelected ? AppTheme.primaryColor : null,
              )),
      subtitle: Text(sublabel, style: Theme.of(context).textTheme.bodySmall),
      trailing: isSelected
          ? const Icon(Icons.check_circle_rounded,
              color: AppTheme.primaryColor, size: 22)
          : null,
      onTap: onTap,
    );
  }
}

// ── Section Header ────────────────────────────────────────────
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

// ── Settings Tile ─────────────────────────────────────────────
class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Color? color;
  const _SettingsTile(
      {required this.icon,
      required this.title,
      this.subtitle,
      this.onTap,
      this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppTheme.darkBorder
                : Colors.white,
            width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: (color ?? AppTheme.primaryColor).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon,
                  color: color ?? AppTheme.lightTextSecondary, size: 20),
            ),
            title: Text(title, style: Theme.of(context).textTheme.titleMedium),
            subtitle: subtitle != null
                ? Text(subtitle!, style: Theme.of(context).textTheme.bodySmall)
                : null,
            trailing:
                const Icon(Icons.chevron_right, color: AppTheme.lightTextHint),
          ),
        ),
      ),
    );
  }
}

// ── Switch Profile Tile ───────────────────────────────────────
class _SwitchProfileTile extends ConsumerWidget {
  const _SwitchProfileTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final mode = ref.watch(profileModeProvider);
    final isPersonal = mode == ProfileMode.personal;
    final accentColor =
        isPersonal ? const Color(0xFF8E44AD) : AppTheme.primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDark ? AppTheme.darkBorder : Colors.white,
            width: 1.5),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            ref.read(profileModeProvider.notifier).toggle();
            AppSnackbar.show(
              context,
              isPersonal ? l.switchedToBusiness : l.switchedToPersonal,
              isSuccess: true,
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutCubic,
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Icon(
                      isPersonal ? Icons.person_rounded : Icons.store_rounded,
                      key: ValueKey(isPersonal),
                      color: accentColor,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.switchProfile,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          )),
                      const SizedBox(height: 2),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: Text(
                          isPersonal
                              ? l.currentlyPersonal
                              : l.currentlyBusiness,
                          key: ValueKey(isPersonal),
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: accentColor,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black26 : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: accentColor.withValues(alpha: 0.1)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _ModeChip(
                        label: l.personal,
                        icon: Icons.person_outline,
                        isActive: isPersonal,
                        activeColor: const Color(0xFF8E44AD),
                      ),
                      _ModeChip(
                        label: l.business,
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
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isActive ? activeColor : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isActive ? [
          BoxShadow(
            color: activeColor.withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ] : [],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 14,
              color: isActive ? Colors.white : AppTheme.lightTextHint),
          const SizedBox(width: 4),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
              color: isActive ? Colors.white : AppTheme.lightTextHint,
              letterSpacing: isActive ? 0.2 : 0.0,
            ),
            child: Text(label),
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
    final l = context.l10n;
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppTheme.darkBorder
                : Colors.white,
            width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
              color: AppTheme.lightTextSecondary,
              size: 20,
            ),
          ),
          title: Text(l.darkMode),
          subtitle: Text(isDark ? l.on : l.off),
          trailing: Switch(
            value: isDark,
            onChanged: (_) =>
                ref.read(themeModeProvider.notifier).toggleTheme(),
          ),
        ),
      ),
    );
  }
}

class _SecurityAppLockTile extends ConsumerStatefulWidget {
  const _SecurityAppLockTile();

  @override
  ConsumerState<_SecurityAppLockTile> createState() => _SecurityAppLockTileState();
}

class _SecurityAppLockTileState extends ConsumerState<_SecurityAppLockTile> {
  bool _isLockEnabled = false;

  @override
  void initState() {
    super.initState();
    _checkLockStatus();
  }

  Future<void> _checkLockStatus() async {
    final enabled = await AppLockService.isEnabled();
    if (mounted) setState(() => _isLockEnabled = enabled);
  }

  Future<void> _toggleLock(bool enable) async {
    final manager = ref.read(subscriptionManagerProvider.notifier);
    final hasAccess = manager.checkFeatureAccess('app_lock');

    if (!hasAccess) {
      AppSnackbar.show(
        context,
        context.l10n.appLockPremiumMsg,
        isError: true,
      );
      context.push(AppRoutes.subscription);
      return;
    }

    if (enable) {
      // 1. Prompt to create PIN
      final pin = await Navigator.push<String>(
        context,
        MaterialPageRoute(
          builder: (context) => PinLockScreen(
            isConfirming: false,
            onPinSuccess: (val) {
              Navigator.pop(context, val);
            },
          ),
        ),
      );

      if (pin != null && pin.isNotEmpty && mounted) {
        // 2. Confirm PIN
        final confirmedPin = await Navigator.push<String>(
          context,
          MaterialPageRoute(
            builder: (context) => PinLockScreen(
              isConfirming: true,
              initialPin: pin,
              onPinSuccess: (val) {
                Navigator.pop(context, val);
              },
            ),
          ),
        );

        if (confirmedPin != null && mounted) {
          await AppLockService.enableLock(confirmedPin);
          if (mounted) {
            AppSnackbar.show(context, 'App Lock enabled successfully!', isSuccess: true);
            setState(() => _isLockEnabled = true);
          }
        }
      }
    } else {
      // Prompt to verify existing PIN before disabling
      final verified = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => const PinLockScreen(),
        ),
      );

      if (verified == true && mounted) {
        await AppLockService.disableLock();
        if (mounted) {
          AppSnackbar.show(context, 'App Lock disabled successfully!', isSuccess: true);
          setState(() => _isLockEnabled = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppTheme.darkBorder
                : Colors.white,
            width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.lock_outline_rounded,
            color: AppTheme.lightTextSecondary,
            size: 20,
          ),
        ),
        title: const Text('App PIN Lock'),
        subtitle: Text(_isLockEnabled ? 'Secure lock enabled' : 'Lock disabled'),
        trailing: Switch(
          value: _isLockEnabled,
          onChanged: _toggleLock,
        ),
      ),
    );
  }
}
