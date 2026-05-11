import 'package:flutter/material.dart';
import 'package:hamro_pasal/core/theme/app_theme.dart';
import 'package:hamro_pasal/core/services/sync_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Displays a small sync status indicator chip
class SyncStatusWidget extends ConsumerWidget {
  const SyncStatusWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivityAsync = ref.watch(connectivityProvider);

    return connectivityAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (status) {
        if (status == ConnectivityStatus.online) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppTheme.successColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6, height: 6,
                  decoration: const BoxDecoration(
                    color: AppTheme.successColor, shape: BoxShape.circle),
                ),
                const SizedBox(width: 4),
                const Text('Synced', style: TextStyle(
                    fontSize: 11, color: AppTheme.successColor, fontWeight: FontWeight.w600)),
              ],
            ),
          );
        }
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppTheme.warningColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6, height: 6,
                decoration: const BoxDecoration(
                    color: AppTheme.warningColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 4),
              const Text('Offline', style: TextStyle(
                  fontSize: 11, color: AppTheme.warningColor, fontWeight: FontWeight.w600)),
            ],
          ),
        );
      },
    );
  }
}

/// Format currency in Nepali style: Rs. 1,00,00,000.00
class CurrencyFormatter {
  static String format(double amount, {bool showSymbol = true}) {
    final prefix = showSymbol ? 'Rs. ' : '';
    final parts = amount.toStringAsFixed(2).split('.');
    final intPart = parts[0];
    final decPart = parts[1];
    final formatted = _formatNepali(intPart);
    return '$prefix$formatted.$decPart';
  }

  static String _formatNepali(String num) {
    if (num.length <= 3) return num;
    final last3 = num.substring(num.length - 3);
    var rest = num.substring(0, num.length - 3);
    final parts = <String>[];
    while (rest.length > 2) {
      parts.insert(0, rest.substring(rest.length - 2));
      rest = rest.substring(0, rest.length - 2);
    }
    if (rest.isNotEmpty) parts.insert(0, rest);
    return '${parts.join(',')},$last3';
  }
}

/// Empty state widget
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: AppTheme.lightTextHint),
            ),
            const SizedBox(height: 20),
            Text(title, style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(subtitle!, style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Loading overlay
class LoadingOverlay extends StatelessWidget {
  final String? message;
  const LoadingOverlay({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.4),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              if (message != null) ...[
                const SizedBox(height: 16),
                Text(message!, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
