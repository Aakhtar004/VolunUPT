import 'package:flutter/material.dart';
import 'package:volunupt/utils/app_colors.dart';

class FeedbackOverlay {
  static Future<void> showSuccess(BuildContext context, String message, {Duration duration = const Duration(milliseconds: 1600)}) {
    return _show(context, message, AppColors.success, Icons.check_circle, duration);
  }

  static Future<void> showError(BuildContext context, String message, {Duration duration = const Duration(milliseconds: 1800)}) {
    return _show(context, message, AppColors.error, Icons.error_outline, duration);
  }

  static Future<void> showInfo(BuildContext context, String message, {Duration duration = const Duration(milliseconds: 1500)}) {
    return _show(context, message, AppColors.accent, Icons.info_outline, duration);
  }

  static Future<void> _show(
    BuildContext context,
    String message,
    Color color,
    IconData icon,
    Duration duration,
  ) async {
    // Usa showGeneralDialog para animación suave y fondo semitransparente
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'feedback',
      barrierColor: Colors.black.withValues(alpha: 0.35),
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (ctx, anim1, anim2) {
        // Captura el navigator fuera del callback para no usar BuildContext tras un gap asíncrono
        final navigator = Navigator.of(ctx, rootNavigator: true);
        // Auto-cerrar después de [duration]
        Future.delayed(duration, () {
          if (!navigator.mounted) return;
          if (navigator.canPop()) {
            navigator.pop();
          }
        });
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              constraints: const BoxConstraints(minWidth: 240, maxWidth: 360),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 48, color: color),
                  const SizedBox(height: 10),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                        ) ?? const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (ctx, anim, secAnim, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
        return FadeTransition(
          opacity: anim,
          child: ScaleTransition(scale: Tween<double>(begin: 0.9, end: 1.0).animate(curved), child: child),
        );
      },
    );
  }
}