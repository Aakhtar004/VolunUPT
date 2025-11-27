import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../models/models.dart';
import '../../services/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  final UserModel user;

  const NotificationsScreen({super.key, required this.user});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    // Limpiar notificaciones antiguas al abrir la pantalla
    NotificationService.cleanOldNotifications(widget.user.uid);
  }

  void _markAsRead(String notificationId) async {
    try {
      await NotificationService.markAsRead(notificationId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudo marcar como leída. Inténtalo de nuevo'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _markAllAsRead() async {
    try {
      await NotificationService.markAllAsRead(widget.user.uid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Todas las notificaciones marcadas como leídas'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudieron marcar todas como leídas'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _deleteNotification(String notificationId) async {
    try {
      await NotificationService.deleteNotification(notificationId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notificación eliminada'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudo eliminar la notificación'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notificaciones',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF1E3A8A),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          StreamBuilder<int>(
            stream: NotificationService.getUnreadNotificationCount(widget.user.uid),
            builder: (context, snapshot) {
              final unreadCount = snapshot.data ?? 0;
              if (unreadCount > 0) {
                return IconButton(
                  icon: const Icon(Icons.done_all, color: Colors.white),
                  onPressed: _markAllAsRead,
                  tooltip: 'Marcar todas como leídas',
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: StreamBuilder<List<NotificationModel>>(
        stream: NotificationService.getUserNotifications(widget.user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E3A8A)),
              ),
            );
          }

          if (snapshot.hasError) {
            // En caso de error (por ejemplo, ausencia de datos/tablas), mostrar estado vacío
            return _buildEmptyState();
          }

          final notifications = snapshot.data ?? [];
          
          if (notifications.isEmpty) {
            return _buildEmptyState();
          }

          final unreadCount = notifications.where((n) => !n.isRead).length;

          return Column(
            children: [
              if (unreadCount > 0)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: const Color(0xFF1E3A8A).withValues(alpha: 0.1),
                  child: Text(
                    'Tienes $unreadCount notificación${unreadCount == 1 ? '' : 'es'} sin leer',
                    style: const TextStyle(
                      color: Color(0xFF1E3A8A),
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    // El StreamBuilder se actualiza automáticamente
                    await Future.delayed(const Duration(milliseconds: 500));
                  },
                  color: const Color(0xFF1E3A8A),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final notification = notifications[index];
                      return _buildNotificationCard(notification);
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No tienes notificaciones',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Las notificaciones aparecerán aquí cuando tengas nuevas actualizaciones',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  

  Widget _buildNotificationCard(NotificationModel notification) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: notification.isRead ? 2 : 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: notification.isRead
            ? BorderSide.none
            : const BorderSide(color: Color(0xFF1E3A8A), width: 1),
      ),
      child: InkWell(
        onTap: () {
          if (!notification.isRead) {
            _markAsRead(notification.notificationId);
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildNotificationIcon(notification.type),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: notification.isRead
                                  ? FontWeight.w500
                                  : FontWeight.bold,
                              color: notification.isRead
                                  ? Colors.grey[700]
                                  : const Color(0xFF1E3A8A),
                            ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF1E3A8A),
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatTimestamp(notification.timestamp),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                        PopupMenuButton<String>(
                          onSelected: (value) {
                            switch (value) {
                              case 'mark_read':
                                _markAsRead(notification.notificationId);
                                break;
                              case 'delete':
                                _deleteNotification(notification.notificationId);
                                break;
                            }
                          },
                          itemBuilder: (context) => [
                            if (!notification.isRead)
                              const PopupMenuItem(
                                value: 'mark_read',
                                child: Row(
                                  children: [
                                    Icon(Icons.done, size: 16),
                                    SizedBox(width: 8),
                                    Text('Marcar como leída'),
                                  ],
                                ),
                              ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, size: 16, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Eliminar', style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                          child: Icon(
                            Icons.more_vert,
                            size: 16,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
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

  Widget _buildNotificationIcon(NotificationType type) {
    IconData icon;
    Color color;

    switch (type) {
      case NotificationType.info:
        icon = Icons.info;
        color = AppColors.primary;
        break;
      case NotificationType.success:
        icon = Icons.check_circle;
        color = AppColors.success;
        break;
      case NotificationType.warning:
        icon = Icons.warning;
        color = AppColors.accent;
        break;
      case NotificationType.error:
        icon = Icons.error;
        color = AppColors.error;
        break;
      case NotificationType.event:
        icon = Icons.event;
        color = AppColors.primary;
        break;
      case NotificationType.certificate:
        icon = Icons.card_membership;
        color = AppColors.success;
        break;
      case NotificationType.registration:
        icon = Icons.person_add;
        color = AppColors.primary;
        break;
      case NotificationType.user:
        icon = Icons.person;
        color = AppColors.primary;
        break;
      case NotificationType.report:
        icon = Icons.assessment;
        color = AppColors.accent;
        break;
      case NotificationType.attendance:
        icon = Icons.check_circle_outline;
        color = AppColors.success;
        break;
      case NotificationType.reminder:
        icon = Icons.notifications_active;
        color = AppColors.accent;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        color: color,
        size: 20,
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Ahora';
    } else if (difference.inHours < 1) {
      return 'Hace ${difference.inMinutes} min';
    } else if (difference.inDays < 1) {
      return 'Hace ${difference.inHours} h';
    } else if (difference.inDays < 7) {
      return 'Hace ${difference.inDays} días';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}