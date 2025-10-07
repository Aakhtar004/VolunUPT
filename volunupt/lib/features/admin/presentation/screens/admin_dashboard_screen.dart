import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../events/presentation/providers/events_providers.dart';
import '../providers/admin_providers.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider).value;
    
    if (currentUser == null) {
      return _buildUnauthenticatedState(context);
    }

    if (currentUser.role != 'gestor_rsu') {
      return _buildUnauthorizedState(context);
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildWelcomeCard(context, currentUser.name),
                const SizedBox(height: 24),
                _buildStatsGrid(context, ref),
                const SizedBox(height: 24),
                _buildQuickActions(context),
                const SizedBox(height: 24),
                _buildRecentActivity(context, ref),
                const SizedBox(height: 24),
                _buildSystemHealth(context, ref),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnauthenticatedState(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Error de Autenticación'),
        backgroundColor: Theme.of(context).colorScheme.error,
        foregroundColor: Theme.of(context).colorScheme.onError,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.person_off,
                size: 80,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 24),
              Text(
                'Usuario no autenticado',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Debes iniciar sesión para acceder al panel de administración',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  context.go('/login');
                },
                icon: const Icon(Icons.login),
                label: const Text('Iniciar Sesión'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUnauthorizedState(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Acceso Denegado'),
        backgroundColor: Theme.of(context).colorScheme.error,
        foregroundColor: Theme.of(context).colorScheme.onError,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.admin_panel_settings_outlined,
                size: 80,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 24),
              Text(
                'Acceso Restringido',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Solo los gestores RSU pueden acceder al panel de administración',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  context.pop();
                },
                icon: const Icon(Icons.arrow_back),
                label: const Text('Volver'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          'Panel de Administración',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.primary.withOpacity(0.8),
              ],
            ),
          ),
          child: const Center(
            child: Icon(
              Icons.admin_panel_settings,
              size: 60,
              color: Colors.white,
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          onPressed: () {
            _showNotificationsDialog(context);
          },
          icon: const Icon(Icons.notifications),
        ),
        IconButton(
          onPressed: () {
            context.go('/admin/settings');
          },
          icon: const Icon(Icons.settings),
        ),
      ],
    );
  }

  Widget _buildWelcomeCard(BuildContext context, String userName) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primaryContainer,
              Theme.of(context).colorScheme.primaryContainer.withOpacity(0.7),
            ],
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.admin_panel_settings,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bienvenido, $userName',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Gestor RSU - ${DateFormat('EEEE, dd MMMM yyyy', 'es').format(DateTime.now())}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, WidgetRef ref) {
    return Consumer(
      builder: (context, ref, child) {
        final statsAsync = ref.watch(adminStatsProvider);
        
        return statsAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (error, stackTrace) => Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    Icons.error,
                    size: 48,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error al cargar estadísticas',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error.toString(),
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          data: (stats) => GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.5,
            children: [
              _StatCard(
                icon: Icons.people,
                title: 'Usuarios Totales',
                value: stats.totalUsers.toString(),
                subtitle: '+${stats.newUsersThisMonth} este mes',
                color: Colors.blue,
              ),
              _StatCard(
                icon: Icons.event,
                title: 'Eventos Activos',
                value: stats.activeEvents.toString(),
                subtitle: '${stats.totalEvents} en total',
                color: Colors.green,
              ),
              _StatCard(
                icon: Icons.assignment,
                title: 'Inscripciones',
                value: stats.totalInscriptions.toString(),
                subtitle: '+${stats.newInscriptionsToday} hoy',
                color: Colors.orange,
              ),
              _StatCard(
                icon: Icons.schedule,
                title: 'Horas Voluntariado',
                value: '${stats.totalVolunteerHours}h',
                subtitle: '+${stats.hoursThisMonth}h este mes',
                color: Colors.purple,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Acciones Rápidas',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 2.5,
          children: [
            _ActionCard(
              icon: Icons.person_add,
              title: 'Gestionar Usuarios',
              onTap: () => context.go('/admin/users'),
            ),
            _ActionCard(
              icon: Icons.event_note,
              title: 'Crear Evento',
              onTap: () => context.go('/admin/events/create'),
            ),
            _ActionCard(
              icon: Icons.analytics,
              title: 'Ver Reportes',
              onTap: () => context.go('/admin/reports'),
            ),
            _ActionCard(
              icon: Icons.settings,
              title: 'Configuración',
              onTap: () => context.go('/admin/settings'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentActivity(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Actividad Reciente',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => context.go('/admin/activity'),
              child: const Text('Ver todo'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Consumer(
          builder: (context, ref, child) {
            final activityAsync = ref.watch(recentActivityProvider);
            
            return activityAsync.when(
              loading: () => const Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
              error: (error, stackTrace) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Error al cargar actividad: $error',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ),
              data: (activities) => Card(
                child: Column(
                  children: activities.take(5).map((activity) => ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getActivityColor(activity.type),
                      child: Icon(
                        _getActivityIcon(activity.type),
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    title: Text(activity.description),
                    subtitle: Text(
                      DateFormat('dd/MM/yyyy HH:mm').format(activity.timestamp),
                    ),
                    trailing: _getActivityStatusChip(activity.type),
                  )).toList(),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSystemHealth(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Estado del Sistema',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Consumer(
          builder: (context, ref, child) {
            final healthAsync = ref.watch(systemHealthProvider);
            
            return healthAsync.when(
              loading: () => const Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
              error: (error, stackTrace) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Error al verificar estado del sistema',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              data: (health) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _HealthIndicator(
                        label: 'Base de Datos',
                        status: health.databaseStatus,
                        details: 'Conexión estable',
                      ),
                      const SizedBox(height: 12),
                      _HealthIndicator(
                        label: 'Autenticación',
                        status: health.authStatus,
                        details: 'Firebase Auth operativo',
                      ),
                      const SizedBox(height: 12),
                      _HealthIndicator(
                        label: 'Almacenamiento',
                        status: health.storageStatus,
                        details: 'Firebase Storage disponible',
                      ),
                      const SizedBox(height: 12),
                      _HealthIndicator(
                        label: 'Notificaciones',
                        status: health.notificationStatus,
                        details: 'FCM funcionando',
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  void _showNotificationsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notificaciones del Sistema'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.info, color: Colors.blue),
                title: const Text('Sistema actualizado'),
                subtitle: const Text('Versión 1.2.0 instalada correctamente'),
                trailing: Text(
                  DateFormat('HH:mm').format(DateTime.now().subtract(const Duration(hours: 2))),
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.warning, color: Colors.orange),
                title: const Text('Mantenimiento programado'),
                subtitle: const Text('Domingo 3:00 AM - 5:00 AM'),
                trailing: Text(
                  DateFormat('HH:mm').format(DateTime.now().subtract(const Duration(hours: 5))),
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.check_circle, color: Colors.green),
                title: const Text('Backup completado'),
                subtitle: const Text('Respaldo diario exitoso'),
                trailing: Text(
                  DateFormat('HH:mm').format(DateTime.now().subtract(const Duration(hours: 8))),
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/admin/notifications');
            },
            child: const Text('Ver todas'),
          ),
        ],
      ),
    );
  }

  Color _getActivityColor(String type) {
    switch (type) {
      case 'user_registration':
        return Colors.blue;
      case 'event_creation':
        return Colors.green;
      case 'inscription':
        return Colors.orange;
      case 'attendance':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getActivityIcon(String type) {
    switch (type) {
      case 'user_registration':
        return Icons.person_add;
      case 'event_creation':
        return Icons.event;
      case 'inscription':
        return Icons.assignment;
      case 'attendance':
        return Icons.check_circle;
      default:
        return Icons.info;
    }
  }

  Widget _getActivityStatusChip(String type) {
    Color color;
    String label;
    
    switch (type) {
      case 'user_registration':
        color = Colors.blue;
        label = 'Nuevo';
        break;
      case 'event_creation':
        color = Colors.green;
        label = 'Creado';
        break;
      case 'inscription':
        color = Colors.orange;
        label = 'Inscrito';
        break;
      case 'attendance':
        color = Colors.purple;
        label = 'Asistió';
        break;
      default:
        color = Colors.grey;
        label = 'Info';
    }

    return Chip(
      label: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
        ),
      ),
      backgroundColor: color,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.1),
              color.withOpacity(0.05),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.trending_up,
                  color: color,
                  size: 16,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HealthIndicator extends StatelessWidget {
  final String label;
  final String status;
  final String details;

  const _HealthIndicator({
    required this.label,
    required this.status,
    required this.details,
  });

  @override
  Widget build(BuildContext context) {
    final isHealthy = status == 'healthy';
    final color = isHealthy ? Colors.green : Colors.red;
    final icon = isHealthy ? Icons.check_circle : Icons.error;

    return Row(
      children: [
        Icon(
          icon,
          color: color,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                details,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            isHealthy ? 'Operativo' : 'Error',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}