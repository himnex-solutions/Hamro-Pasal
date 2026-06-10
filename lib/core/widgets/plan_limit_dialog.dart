import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_saoji/core/services/daily_limit_service.dart';

/// Shows a beautiful dialog when a Gold plan user hits their daily limit
/// or tries to access a Diamond-only feature.
class PlanLimitDialog {
  PlanLimitDialog._();

  /// Call this when a user hits their daily action limit.
  static Future<void> showDailyLimitReached(
    BuildContext context, {
    required String planCode,
    required String action,
    required int limit,
    required int used,
  }) {
    final planName = planCode.toLowerCase() == 'basic' ? 'Free' : 'Gold';
    return showDialog(
      context: context,
      builder: (_) => _LimitDialog(
        icon: Icons.hourglass_bottom_rounded,
        iconColor: const Color(0xFFE6A817),
        title: 'Daily Limit Reached',
        subtitle:
            'Daily limit of $limit ${DailyLimitService.actionLabel(action)} reached on $planName plan.',
        note: 'Resets at midnight • Upgrade for unlimited access.',
        primaryLabel: 'Upgrade to Diamond',
        onPrimary: () {
          Navigator.of(context).pop();
          context.push('/subscription');
        },
      ),
    );
  }

  /// Call this when a Gold/Basic user tries a Diamond-only feature.
  static Future<void> showDiamondFeatureRequired(
    BuildContext context, {
    required String featureName,
  }) {
    return showDialog(
      context: context,
      builder: (_) => _LimitDialog(
        icon: Icons.diamond_rounded,
        iconColor: const Color(0xFF7C3AED),
        title: '💎 Diamond Feature',
        subtitle: '$featureName is a 💎 Diamond-only feature.',
        note: 'Upgrade to unlock unlimited access.',
        primaryLabel: 'Upgrade to Diamond',
        onPrimary: () {
          Navigator.of(context).pop();
          context.push('/subscription');
        },
      ),
    );
  }
}

class _LimitDialog extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String note;
  final String primaryLabel;
  final VoidCallback onPrimary;

  const _LimitDialog({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.note,
    required this.primaryLabel,
    required this.onPrimary,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon badge
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 36, color: iconColor),
              ),
              const SizedBox(height: 20),
      
              // Title
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
      
              // Subtitle
              Text(
                subtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
      
              // Note box
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: iconColor.withValues(alpha: 0.25)),
                ),
                child: Text(
                  note,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: iconColor.withValues(alpha: 0.85),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
      
              // Upgrade button
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onPrimary,
                  style: FilledButton.styleFrom(
                    backgroundColor: iconColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.rocket_launch_rounded, size: 18),
                  label: Text(
                    primaryLabel,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                ),
              ),
              const SizedBox(height: 10),
      
              // Dismiss
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Maybe Later',
                  style: TextStyle(
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
