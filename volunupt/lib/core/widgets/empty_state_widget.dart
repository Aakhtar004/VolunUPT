import 'package:flutter/material.dart';

class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionText;
  final VoidCallback? onActionPressed;
  final Color? iconColor;
  final bool showAction;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionText,
    this.onActionPressed,
    this.iconColor,
    this.showAction = true,
  });

  const EmptyStateWidget.noEvents({
    super.key,
    this.actionText = 'Explorar eventos',
    this.onActionPressed,
  })  : icon = Icons.event_busy,
        title = 'No hay eventos disponibles',
        message = 'Aún no se han creado eventos. ¡Vuelve pronto para ver nuevas oportunidades de voluntariado!',
        iconColor = Colors.orange,
        showAction = true;

  const EmptyStateWidget.noCertificates({
    super.key,
    this.actionText = 'Ver eventos',
    this.onActionPressed,
  })  : icon = Icons.workspace_premium,
        title = 'No tienes certificados',
        message = 'Participa en eventos de voluntariado para obtener certificados que reconozcan tu contribución.',
        iconColor = Colors.amber,
        showAction = true;

  const EmptyStateWidget.noInscriptions({
    super.key,
    this.actionText = 'Buscar eventos',
    this.onActionPressed,
  })  : icon = Icons.assignment_turned_in,
        title = 'No tienes inscripciones',
        message = 'No estás inscrito en ningún evento. ¡Encuentra eventos que te interesen y únete!',
        iconColor = Colors.blue,
        showAction = true;

  const EmptyStateWidget.noUsers({
    super.key,
    this.actionText = 'Actualizar',
    this.onActionPressed,
  })  : icon = Icons.people_outline,
        title = 'No hay usuarios registrados',
        message = 'Aún no hay usuarios registrados en la plataforma.',
        iconColor = Colors.grey,
        showAction = true;

  const EmptyStateWidget.noNotifications({
    super.key,
    this.actionText = null,
    this.onActionPressed = null,
  })  : icon = Icons.notifications_none,
        title = 'No hay notificaciones',
        message = 'No tienes notificaciones pendientes. Te mantendremos informado sobre eventos y actualizaciones.',
        iconColor = Colors.grey,
        showAction = false;

  const EmptyStateWidget.noConnection({
    super.key,
    this.actionText = 'Reintentar',
    this.onActionPressed,
  })  : icon = Icons.wifi_off,
        title = 'Sin conexión',
        message = 'No se pudo conectar con el servidor. Verifica tu conexión a internet e intenta nuevamente.',
        iconColor = Colors.red,
        showAction = true;

  const EmptyStateWidget.error({
    super.key,
    this.actionText = 'Reintentar',
    this.onActionPressed,
  })  : icon = Icons.error_outline,
        title = 'Error al cargar datos',
        message = 'Ocurrió un error al cargar la información. Por favor, intenta nuevamente.',
        iconColor = Colors.red,
        showAction = true;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: (iconColor ?? Colors.grey).withOpacity(0.1),
                borderRadius: BorderRadius.circular(60),
              ),
              child: Icon(
                icon,
                size: 60,
                color: iconColor ?? Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            if (showAction && actionText != null && onActionPressed != null) ...[
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: onActionPressed,
                icon: const Icon(Icons.refresh),
                label: Text(actionText!),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class LoadingStateWidget extends StatelessWidget {
  final String? message;

  const LoadingStateWidget({
    super.key,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

class ErrorStateWidget extends StatelessWidget {
  final String? title;
  final String? message;
  final VoidCallback? onRetry;

  const ErrorStateWidget({
    super.key,
    this.title,
    this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget.error(
      actionText: 'Reintentar',
      onActionPressed: onRetry,
    );
  }
}