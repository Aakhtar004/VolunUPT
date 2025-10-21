import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/widgets/async_value_widget.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/admin_providers.dart';

class AdminNotificationsScreen extends ConsumerStatefulWidget {
  const AdminNotificationsScreen({super.key});

  @override
  ConsumerState<AdminNotificationsScreen> createState() => _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends ConsumerState<AdminNotificationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  String _selectedUserType = 'all';
  bool _isUrgent = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Notificaciones'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/admin'),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.send), text: 'Enviar'),
            Tab(icon: Icon(Icons.history), text: 'Historial'),
            Tab(icon: Icon(Icons.settings), text: 'Configuración'),
          ],
        ),
      ),
      body: authState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error: $error'),
        ),
        data: (user) {
          if (user == null) {
            return const Center(child: Text('Usuario no autenticado'));
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildSendNotificationTab(),
              _buildNotificationHistoryTab(),
              _buildNotificationSettingsTab(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSendNotificationTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nueva Notificación',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Título',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.title),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _messageController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Mensaje',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.message),
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedUserType,
                    decoration: const InputDecoration(
                      labelText: 'Destinatarios',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.group),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('Todos los usuarios')),
                      DropdownMenuItem(value: 'estudiante', child: Text('Solo estudiantes')),
                      DropdownMenuItem(value: 'coordinador', child: Text('Solo coordinadores')),
                      DropdownMenuItem(value: 'gestor_rsu', child: Text('Solo gestores RSU')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedUserType = value ?? 'all';
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  CheckboxListTile(
                    title: const Text('Notificación Urgente'),
                    subtitle: const Text('Se mostrará como prioritaria'),
                    value: _isUrgent,
                    onChanged: (value) {
                      setState(() {
                        _isUrgent = value ?? false;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _previewNotification,
                          icon: const Icon(Icons.preview),
                          label: const Text('Vista Previa'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _sendNotification,
                          icon: const Icon(Icons.send),
                          label: const Text('Enviar'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildQuickTemplates(),
        ],
      ),
    );
  }

  Widget _buildQuickTemplates() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Plantillas Rápidas',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _TemplateChip(
                  label: 'Mantenimiento',
                  onTap: () => _useTemplate(
                    'Mantenimiento Programado',
                    'El sistema estará en mantenimiento el día de mañana de 2:00 AM a 4:00 AM.',
                  ),
                ),
                _TemplateChip(
                  label: 'Nuevo Evento',
                  onTap: () => _useTemplate(
                    'Nuevo Evento Disponible',
                    'Se ha publicado un nuevo evento de voluntariado. ¡Revisa los detalles e inscríbete!',
                  ),
                ),
                _TemplateChip(
                  label: 'Recordatorio',
                  onTap: () => _useTemplate(
                    'Recordatorio de Evento',
                    'Te recordamos que tienes un evento programado para mañana. ¡No olvides asistir!',
                  ),
                ),
                _TemplateChip(
                  label: 'Actualización',
                  onTap: () => _useTemplate(
                    'Actualización del Sistema',
                    'Hemos actualizado la plataforma con nuevas funcionalidades. Explora las mejoras.',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationHistoryTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: 'Buscar notificaciones...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.filter_list),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: _mockNotifications.length,
              itemBuilder: (context, index) {
                final notification = _mockNotifications[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: notification['isUrgent'] 
                          ? Colors.red 
                          : Theme.of(context).colorScheme.primary,
                      child: Icon(
                        notification['isUrgent'] 
                            ? Icons.priority_high 
                            : Icons.notifications,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(notification['title']),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(notification['message']),
                        const SizedBox(height: 4),
                        Text(
                          'Enviado: ${DateFormat('dd/MM/yyyy HH:mm').format(notification['sentAt'])}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    trailing: PopupMenuButton(
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'view',
                          child: Row(
                            children: [
                              Icon(Icons.visibility),
                              SizedBox(width: 8),
                              Text('Ver detalles'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'resend',
                          child: Row(
                            children: [
                              Icon(Icons.refresh),
                              SizedBox(width: 8),
                              Text('Reenviar'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Eliminar', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                      onSelected: (value) => _handleNotificationAction(value, notification),
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Configuración de Notificaciones',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Notificaciones Push'),
                    subtitle: const Text('Enviar notificaciones push a dispositivos móviles'),
                    value: true,
                    onChanged: (value) {},
                  ),
                  SwitchListTile(
                    title: const Text('Notificaciones por Email'),
                    subtitle: const Text('Enviar notificaciones por correo electrónico'),
                    value: true,
                    onChanged: (value) {},
                  ),
                  SwitchListTile(
                    title: const Text('Notificaciones en la App'),
                    subtitle: const Text('Mostrar notificaciones dentro de la aplicación'),
                    value: true,
                    onChanged: (value) {},
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Estadísticas',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _StatisticItem(
                    icon: Icons.send,
                    label: 'Notificaciones Enviadas',
                    value: '1,234',
                    color: Colors.blue,
                  ),
                  _StatisticItem(
                    icon: Icons.visibility,
                    label: 'Notificaciones Leídas',
                    value: '987',
                    color: Colors.green,
                  ),
                  _StatisticItem(
                    icon: Icons.touch_app,
                    label: 'Tasa de Interacción',
                    value: '78%',
                    color: Colors.orange,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _useTemplate(String title, String message) {
    setState(() {
      _titleController.text = title;
      _messageController.text = message;
    });
  }

  void _previewNotification() {
    if (_titleController.text.isEmpty || _messageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor complete el título y mensaje'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              _isUrgent ? Icons.priority_high : Icons.notifications,
              color: _isUrgent ? Colors.red : null,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(_titleController.text)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_messageController.text),
            const SizedBox(height: 16),
            Text(
              'Destinatarios: ${_getUserTypeText()}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (_isUrgent)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'URGENTE',
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _sendNotification();
            },
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
  }

  void _sendNotification() {
    if (_titleController.text.isEmpty || _messageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor complete todos los campos'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Enviando notificación...'),
          ],
        ),
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notificación enviada exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
      
      setState(() {
        _titleController.clear();
        _messageController.clear();
        _selectedUserType = 'all';
        _isUrgent = false;
      });
    });
  }

  void _handleNotificationAction(String action, Map<String, dynamic> notification) {
    switch (action) {
      case 'view':
        _showNotificationDetails(notification);
        break;
      case 'resend':
        _resendNotification(notification);
        break;
      case 'delete':
        _deleteNotification(notification);
        break;
    }
  }

  void _showNotificationDetails(Map<String, dynamic> notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(notification['title']),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification['message']),
            const SizedBox(height: 16),
            Text(
              'Enviado: ${DateFormat('dd/MM/yyyy HH:mm').format(notification['sentAt'])}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              'Destinatarios: ${notification['recipients']}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _resendNotification(Map<String, dynamic> notification) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notificación reenviada'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _deleteNotification(Map<String, dynamic> notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Notificación'),
        content: const Text('¿Está seguro de que desea eliminar esta notificación?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Notificación eliminada'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  String _getUserTypeText() {
    switch (_selectedUserType) {
      case 'all':
        return 'Todos los usuarios';
      case 'estudiante':
        return 'Solo estudiantes';
      case 'coordinador':
        return 'Solo coordinadores';
      case 'gestor_rsu':
        return 'Solo gestores RSU';
      default:
        return 'Todos los usuarios';
    }
  }

  final List<Map<String, dynamic>> _mockNotifications = [
    {
      'title': 'Mantenimiento Programado',
      'message': 'El sistema estará en mantenimiento mañana de 2:00 AM a 4:00 AM.',
      'sentAt': DateTime.now().subtract(const Duration(hours: 2)),
      'recipients': 'Todos los usuarios',
      'isUrgent': true,
    },
    {
      'title': 'Nuevo Evento Disponible',
      'message': 'Se ha publicado un nuevo evento de voluntariado.',
      'sentAt': DateTime.now().subtract(const Duration(days: 1)),
      'recipients': 'Solo estudiantes',
      'isUrgent': false,
    },
    {
      'title': 'Recordatorio de Evento',
      'message': 'Tienes un evento programado para mañana.',
      'sentAt': DateTime.now().subtract(const Duration(days: 2)),
      'recipients': 'Usuarios específicos',
      'isUrgent': false,
    },
  ];
}

class _TemplateChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _TemplateChip({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
    );
  }
}

class _StatisticItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatisticItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(label),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}