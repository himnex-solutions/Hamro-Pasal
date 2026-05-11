import 'package:flutter/material.dart';
import 'package:hamro_pasal/core/theme/app_theme.dart';

class AppSnackbar {
  static void show(
    BuildContext context,
    String message, {
    bool isSuccess = false,
    bool isError = false,
    Duration duration = const Duration(seconds: 3),
  }) {
    final color = isSuccess
        ? AppTheme.successColor
        : isError
            ? AppTheme.errorColor
            : AppTheme.infoColor;

    final icon = isSuccess
        ? Icons.check_circle_outline
        : isError
            ? Icons.error_outline
            : Icons.info_outline;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(message,
                    style: const TextStyle(color: Colors.white, fontSize: 14)),
              ),
            ],
          ),
          backgroundColor: color,
          duration: duration,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(12),
        ),
      );
  }
}
