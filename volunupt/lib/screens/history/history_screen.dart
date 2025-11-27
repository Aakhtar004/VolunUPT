import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../models/models.dart';
import '../../services/services.dart';

class HistoryScreen extends StatefulWidget {
  final UserModel user;

  const HistoryScreen({super.key, required this.user});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Historial'),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                _selectedFilter = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'all',
                child: Text('Todas las actividades'),
              ),
              const PopupMenuItem(
                value: 'confirmed',
                child: Text('Solo confirmadas'),
              ),
              const PopupMenuItem(
                value: 'pending',
                child: Text('Solo pendientes'),
              ),
              const PopupMenuItem(
                value: 'rejected',
                child: Text('Solo rechazadas'),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Resumen'),
            Tab(text: 'Historial'),
            Tab(text: 'Estadísticas'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildSummaryTab(), _buildHistoryTab(), _buildStatsTab()],
      ),
    );
  }

  Widget _buildSummaryTab() {
    return FutureBuilder<double>(
      future: HistoryService.getUserTotalConfirmedHours(widget.user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final totalHours = snapshot.data ?? 0.0;

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Resumen de horas
              _buildHoursSummaryCard(totalHours),
              const SizedBox(height: 24),

              // Actividades recientes
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Actividades Recientes',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E3A8A),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: FutureBuilder<List<Map<String, dynamic>>>(
                        future: HistoryService.getUserDetailedHistory(
                          widget.user.uid,
                        ).then((activities) => activities.take(5).toList()),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          if (snapshot.hasError) {
                            // En caso de error (p.ej., ausencia de datos/tablas), mostrar estado vacío
                            return _buildEmptyState();
                          }

                          final activities = snapshot.data ?? [];

                          if (activities.isEmpty) {
                            return _buildEmptyState();
                          }

                          return ListView.builder(
                            itemCount: activities.length,
                            itemBuilder: (context, index) {
                              final activity = activities[index];
                              return _buildActivityCardWithData(activity);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHistoryTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: HistoryService.getUserDetailedHistory(widget.user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          // Tratar errores como estado vacío para evitar mostrar detalles técnicos
          return _buildEmptyState();
        }

        final allActivities = snapshot.data ?? [];

        // Filtrar actividades según el filtro seleccionado
        final filteredActivities = _filterDetailedActivities(allActivities);

        if (filteredActivities.isEmpty) {
          return _buildEmptyState();
        }

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Historial Completo (${filteredActivities.length} actividades)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E3A8A),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: filteredActivities.length,
                  itemBuilder: (context, index) {
                    final activity = filteredActivities[index];
                    return _buildDetailedActivityCardWithData(activity);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatsTab() {
    return FutureBuilder<double>(
      future: HistoryService.getUserTotalConfirmedHours(widget.user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          // Tratar errores como estado vacío para evitar mostrar detalles técnicos
          return _buildEmptyState();
        }

        final totalHours = snapshot.data ?? 0.0;

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Estadísticas de Participación',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E3A8A),
                ),
              ),
              const SizedBox(height: 24),

              // Tarjetas de estadísticas
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.2,
                  children: [
                    _buildStatCard(
                      'Horas Confirmadas',
                      '${totalHours.toStringAsFixed(1)}h',
                      Icons.check_circle,
                      AppColors.success,
                    ),
                    _buildStatCard(
                      'Total de Horas',
                      '${totalHours.toStringAsFixed(1)}h',
                      Icons.access_time,
                      AppColors.primary,
                    ),
                    _buildStatCard(
                      'Estado',
                      'Activo',
                      Icons.person,
                      AppColors.primary,
                    ),
                    _buildStatCard(
                      'Progreso',
                      '100%',
                      Icons.trending_up,
                      AppColors.accent,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHoursSummaryCard(double totalHours) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.access_time,
                color: Color(0xFF10B981),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total de Horas Confirmadas',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${totalHours.toStringAsFixed(1)} horas',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF10B981),
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

  Widget _buildActivityCardWithData(Map<String, dynamic> detailedActivity) {
    final attendance = detailedActivity['attendance'] as AttendanceRecordModel;
    final subEventName =
        detailedActivity['subEventName'] as String? ?? 'Actividad sin nombre';
    final eventName =
        detailedActivity['eventName'] as String? ?? 'Evento sin nombre';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildStatusIcon(attendance.status),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subEventName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        eventName,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${attendance.hoursEarned.toStringAsFixed(1)}h',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF10B981),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _formatDate(attendance.checkInTime),
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedActivityCardWithData(
    Map<String, dynamic> detailedActivity,
  ) {
    final attendance = detailedActivity['attendance'] as AttendanceRecordModel;
    final subEventName =
        detailedActivity['subEventName'] as String? ?? 'Actividad sin nombre';
    final eventName =
        detailedActivity['eventName'] as String? ?? 'Evento sin nombre';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildStatusIcon(attendance.status),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subEventName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        eventName,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(attendance.status),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildInfoChip(
                  Icons.access_time,
                  '${attendance.hoursEarned.toStringAsFixed(1)} horas',
                  AppColors.primary,
                ),
                const SizedBox(width: 8),
                _buildInfoChip(
                  Icons.calendar_today,
                  _formatDate(attendance.checkInTime),
                  Colors.grey,
                ),
              ],
            ),
            if (attendance.status == AttendanceStatus.absent) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.red, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Asistencia marcada como ausente',
                        style: const TextStyle(fontSize: 12, color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.validated:
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.check_circle, color: AppColors.success, size: 20),
        );
      case AttendanceStatus.checkedIn:
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.pending, color: AppColors.accent, size: 20),
        );
      case AttendanceStatus.absent:
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.cancel, color: AppColors.error, size: 20),
        );
    }
  }

  Widget _buildStatusChip(AttendanceStatus status) {
    Color color;
    String label;

    switch (status) {
      case AttendanceStatus.validated:
        color = AppColors.success;
        label = 'Confirmada';
        break;
      case AttendanceStatus.checkedIn:
        color = AppColors.accent;
        label = 'Pendiente';
        break;
      case AttendanceStatus.absent:
        color = AppColors.error;
        label = 'Rechazada';
        break;
    }

    return Chip(
      label: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 10),
      ),
      backgroundColor: color,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No hay actividades registradas',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            'Tus actividades aparecerán aquí una vez que participes en eventos',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _filterDetailedActivities(
    List<Map<String, dynamic>> activities,
  ) {
    if (_selectedFilter == 'all') {
      return activities;
    }

    return activities.where((detailedActivity) {
      final attendance =
          detailedActivity['attendance'] as AttendanceRecordModel;
      switch (_selectedFilter) {
        case 'confirmed':
          return attendance.status == AttendanceStatus.validated;
        case 'pending':
          return attendance.status == AttendanceStatus.checkedIn;
        case 'rejected':
          return attendance.status == AttendanceStatus.absent;
        default:
          return true;
      }
    }).toList();
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
