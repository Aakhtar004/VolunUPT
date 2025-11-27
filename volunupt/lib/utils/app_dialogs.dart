import 'package:flutter/material.dart';
import 'package:volunupt/utils/app_colors.dart';

class AppDialogs {
  static Future<T?> modal<T>(
    BuildContext context, {
    required String title,
    required Widget content,
    List<Widget>? actions,
    IconData icon = Icons.info_outline,
    Color iconColor = AppColors.primary,
    bool barrierDismissible = false,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        actionsPadding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        title: Row(
          children: [
            Icon(icon, color: iconColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(title, style: Theme.of(ctx).textTheme.titleLarge),
            ),
          ],
        ),
        content: content,
        actions: actions ?? const <Widget>[],
      ),
    );
  }

  /// Botón primario coherente con AppColors.primary
  static Widget primaryAction({
    required String label,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      child: Text(label),
    );
  }

  /// Botón de peligro (rechazar)
  static Widget dangerAction({
    required String label,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.error,
        foregroundColor: Colors.white,
      ),
      child: Text(label),
    );
  }

  /// Botón texto cancelar.
  static Widget cancelAction({
    String label = 'Cancelar',
    VoidCallback? onPressed,
  }) {
    return TextButton(onPressed: onPressed, child: Text(label));
  }
}
