import 'package:flutter/material.dart';
import 'app_colors.dart';

class UiFeedback {
  static void showSuccess(BuildContext context, String message) {
    _showSnack(context, message, AppColors.success);
  }

  static void showError(BuildContext context, String message, {VoidCallback? onRetry}) {
    final snackBar = SnackBar(
      content: Text(message, style: const TextStyle(color: Colors.white)),
      backgroundColor: AppColors.error,
      behavior: SnackBarBehavior.floating,
      action: onRetry != null
          ? SnackBarAction(label: 'Reintentar', onPressed: onRetry)
          : null,
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  static void showInfo(BuildContext context, String message) {
    _showSnack(context, message, AppColors.primary);
  }

  static void _showSnack(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}