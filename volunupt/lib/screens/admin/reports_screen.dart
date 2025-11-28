import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/models.dart';
import '../../utils/app_colors.dart';
import '../../utils/skeleton_loader.dart';
import '../../services/services.dart';

class ReportsScreen extends StatefulWidget {
  final UserModel user;

  const ReportsScreen({
    super.key,
    required this.user,
  });

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _selectedPeriod = 'month';
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text(
          'Reportes y Estadísticas',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: () => _exportReports(),
            icon: const Icon(Icons.download),
            tooltip: 'Exportar Reportes',
          ),
          IconButton(
            onPressed: () => setState(() {}),
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildPeriodSelector(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => setState(() {}),
              color: AppColors.primary,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildOverviewCards(),
                    const SizedBox(height: 24),
                    _buildUserMetrics(),
                    const SizedBox(height: 24),
                    _buildEventMetrics(),
                    const SizedBox(height: 24),
                    _buildAttendanceMetrics(),
                    const SizedBox(height: 24),
                    _buildCertificateMetrics(),
                    const SizedBox(height: 24),
                    _buildTopPerformers(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Período de análisis',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildPeriodChip('week', 'Esta semana'),
                      const SizedBox(width: 8),
                      _buildPeriodChip('month', 'Este mes'),
                      const SizedBox(width: 8),
                      _buildPeriodChip('quarter', 'Este trimestre'),
                      const SizedBox(width: 8),
                      _buildPeriodChip('year', 'Este año'),
                      const SizedBox(width: 8),
                      _buildPeriodChip('all', 'Todo el tiempo'),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              OutlinedButton.icon(
                onPressed: () => _selectCustomDate(),
                icon: const Icon(Icons.calendar_today, size: 18),
                label: const Text('Personalizar'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodChip(String value, String label) {
    final isSelected = _selectedPeriod == value;
    return FilterChip(
      selected: isSelected,
      onSelected: (selected) => setState(() => _selectedPeriod = value),
      label: Text(label),
      selectedColor: AppColors.primary,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.primary,
        fontWeight: FontWeight.w500,
      ),
      backgroundColor: Colors.white,
      side: BorderSide(
        color: isSelected ? AppColors.primary : Colors.grey[300]!,
      ),
    );
  }

  Widget _buildOverviewCards() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _getOverviewData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Resumen General',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.5,
                children: const [
                  StatCardSkeleton(),
                  StatCardSkeleton(),
                  StatCardSkeleton(),
                  StatCardSkeleton(),
                ],
              ),
            ],
          );
        }

        if (snapshot.hasError) {
          return _buildErrorCard('Error al cargar resumen general');
        }

        final data = snapshot.data ?? {};
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Resumen General',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.5,
              children: [
                _buildOverviewCard(
                  'Usuarios Totales',
                  data['activeUsers']?.toString() ?? '0',
                  Icons.people,
                  AppColors.primary,
                  '${data['newUsers'] ?? 0} nuevos',
                ),
                _buildOverviewCard(
                  'Eventos Activos',
                  data['activeEvents']?.toString() ?? '0',
                  Icons.event,
                  AppColors.primary,
                  '${data['totalSubEvents'] ?? 0} actividades',
                ),
                _buildOverviewCard(
                  'Horas Voluntariado',
                  '${data['totalHours'] ?? 0}h',
                  Icons.access_time,
                  AppColors.success,
                  '+${data['hoursThisPeriod'] ?? 0}h período',
                ),
                _buildOverviewCard(
                  'Certificados',
                  data['totalCertificates']?.toString() ?? '0',
                  Icons.card_membership,
                  AppColors.accent,
                  '${data['pendingCertificates'] ?? 0} elegibles',
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildOverviewCard(String title, String value, IconData icon, Color color, String subtitle) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(Icons.trending_up, color: color, size: 16),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserMetrics() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _getUserMetrics(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildMetricSection(
            'Métricas de Usuarios',
            Icons.people,
            [const ListItemSkeleton()],
          );
        }

        if (snapshot.hasError) {
          return _buildErrorCard('Error al cargar métricas de usuarios');
        }

        final data = snapshot.data ?? {};
        
        return _buildMetricSection(
          'Métricas de Usuarios',
          Icons.people,
          [
            _buildMetricRow('Total de usuarios', data['totalUsers']?.toString() ?? '0'),
            _buildMetricRow('Estudiantes', data['students']?.toString() ?? '0'),
            _buildMetricRow('Coordinadores', data['coordinators']?.toString() ?? '0'),
            _buildMetricRow('Administradores', data['admins']?.toString() ?? '0'),
            _buildMetricRow('Usuarios con horas', data['usersWithHours']?.toString() ?? '0'),
          ],
        );
      },
    );
  }

  Widget _buildEventMetrics() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _getEventMetrics(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildMetricSection(
            'Métricas de Eventos',
            Icons.event,
            [const ListItemSkeleton()],
          );
        }

        if (snapshot.hasError) {
          return _buildErrorCard('Error al cargar métricas de eventos');
        }

        final data = snapshot.data ?? {};
        
        return _buildMetricSection(
          'Métricas de Eventos',
          Icons.event,
          [
            _buildMetricRow('Programas totales', data['totalEvents']?.toString() ?? '0'),
            _buildMetricRow('Programas publicados', data['publishedEvents']?.toString() ?? '0'),
            _buildMetricRow('Actividades totales', data['totalSubEvents']?.toString() ?? '0'),
            _buildMetricRow('Actividades pasadas', data['pastSubEvents']?.toString() ?? '0'),
            _buildMetricRow('Actividades futuras', data['upcomingSubEvents']?.toString() ?? '0'),
          ],
        );
      },
    );
  }

  Widget _buildAttendanceMetrics() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _getAttendanceMetrics(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildMetricSection(
            'Métricas de Asistencia',
            Icons.check_circle,
            [const ListItemSkeleton()],
          );
        }

        if (snapshot.hasError) {
          return _buildErrorCard('Error al cargar métricas de asistencia');
        }

        final data = snapshot.data ?? {};
        
        return _buildMetricSection(
          'Métricas de Asistencia',
          Icons.check_circle,
          [
            _buildMetricRow('Registros totales', data['totalRecords']?.toString() ?? '0'),
            _buildMetricRow('Confirmadas', data['confirmedRecords']?.toString() ?? '0'),
            _buildMetricRow('Pendientes', data['pendingRecords']?.toString() ?? '0'),
            _buildMetricRow('Horas confirmadas', '${data['totalConfirmedHours']?.toStringAsFixed(1) ?? '0'}h'),
            _buildMetricRow('Tasa de confirmación', '${data['confirmationRate']?.toStringAsFixed(1) ?? '0'}%'),
          ],
        );
      },
    );
  }

  Widget _buildCertificateMetrics() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _getCertificateMetrics(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildMetricSection(
            'Métricas de Certificados',
            Icons.card_membership,
            [const ListItemSkeleton()],
          );
        }

        if (snapshot.hasError) {
          return _buildErrorCard('Error al cargar métricas de certificados');
        }

        final data = snapshot.data ?? {};
        
        return _buildMetricSection(
          'Métricas de Certificados',
          Icons.card_membership,
          [
            _buildMetricRow('Certificados emitidos', data['totalCertificates']?.toString() ?? '0'),
            _buildMetricRow('Estudiantes certificados', data['uniqueStudents']?.toString() ?? '0'),
            _buildMetricRow('Programa más popular', data['topProgramName'] ?? 'N/A'),
            _buildMetricRow('Certificados del programa', data['topProgramCount']?.toString() ?? '0'),
          ],
        );
      },
    );
  }

  Widget _buildTopPerformers() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _getTopPerformers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Destacados del Período',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Expanded(child: ListItemSkeleton()),
                  SizedBox(width: 16),
                  Expanded(child: ListItemSkeleton()),
                ],
              ),
            ],
          );
        }

        if (snapshot.hasError) {
          return _buildErrorCard('Error al cargar usuarios destacados');
        }

        final data = snapshot.data ?? {};
        final topStudents = (data['topStudents'] as List<dynamic>?)
            ?.map((e) => Map<String, dynamic>.from(e as Map))
            .toList() ?? <Map<String, dynamic>>[];
        final topCoordinators = (data['topCoordinators'] as List<dynamic>?)
            ?.map((e) => Map<String, dynamic>.from(e as Map))
            .toList() ?? <Map<String, dynamic>>[];
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Destacados del Período',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildTopPerformersCard(
                    'Estudiantes Destacados',
                    Icons.school,
                    AppColors.success,
                    topStudents,
                    'horas',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTopPerformersCard(
                    'Coordinadores Activos',
                    Icons.supervisor_account,
                    AppColors.accent,
                    topCoordinators,
                    'eventos',
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetricSection(String title, IconData icon, List<Widget> metrics) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 24),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...metrics,
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopPerformersCard(String title, IconData icon, Color color, List<Map<String, dynamic>> performers, String metric) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (performers.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'No hay datos disponibles',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
              )
            else
              ...performers.take(5).map((performer) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: color.withValues(alpha: 0.1),
                      backgroundImage: performer['photoURL'] != null && performer['photoURL'].toString().isNotEmpty
                          ? NetworkImage(performer['photoURL'])
                          : null,
                      child: performer['photoURL'] == null || performer['photoURL'].toString().isEmpty
                          ? Text(
                              performer['name']?.toString().substring(0, 1).toUpperCase() ?? 'U',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        performer['name'] ?? 'Usuario',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${performer['value'] is double ? (performer['value'] as double).toStringAsFixed(1) : performer['value'] ?? 0} $metric',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ],
                ),
              )),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(String message) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _selectCustomDate() {
    showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    ).then((date) {
      if (date != null) {
        setState(() {
          _selectedDate = date;
          _selectedPeriod = 'custom';
        });
      }
    });
  }

  void _exportReports() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funcionalidad de exportación en desarrollo'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  // ==================== MÉTODOS DE DATOS REALES ====================

  Future<Map<String, dynamic>> _getOverviewData() async {
    try {
      final dateRange = _getDateRange();
      
      // Obtener usuarios
      final usersQuery = await FirebaseFirestore.instance.collection('users').get();
      final users = usersQuery.docs;
      
      // Contar nuevos usuarios en el período
      int newUsers = 0;
      if (dateRange != null) {
        newUsers = users.where((doc) {
          final timestamp = doc.data()['createdAt'] as Timestamp?;
          if (timestamp == null) return false;
          return timestamp.toDate().isAfter(dateRange['start']!);
        }).length;
      }

      // Obtener eventos activos (publicados)
      final eventsQuery = await FirebaseFirestore.instance
          .collection('events')
          .where('status', isEqualTo: 'publicado')
          .get();
      
      // Obtener todas las actividades
      final subEventsQuery = await FirebaseFirestore.instance
          .collection('subEvents')
          .get();

      // Calcular horas totales y del período
      double totalHours = 0;
      double hoursThisPeriod = 0;
      
      for (final user in users) {
        final userHours = (user.data()['totalHours'] ?? 0).toDouble();
        totalHours += userHours;
      }

      // Horas del período desde attendance records confirmados
      if (dateRange != null) {
        // Obtener todos los confirmados y filtrar en código para evitar índice compuesto
        final periodAttendanceQuery = await FirebaseFirestore.instance
            .collection('attendanceRecords')
            .where('status', isEqualTo: 'confirmed')
            .get();
        
        for (final doc in periodAttendanceQuery.docs) {
          final validatedAt = doc.data()['validatedAt'] as Timestamp?;
          if (validatedAt != null && validatedAt.toDate().isAfter(dateRange['start']!)) {
            hoursThisPeriod += (doc.data()['hoursEarned'] ?? 0).toDouble();
          }
        }
      }

      // Obtener certificados
      final certificatesQuery = await FirebaseFirestore.instance
          .collection('certificates')
          .get();
      
      // Contar estudiantes elegibles para certificados
      int pendingCertificates = 0;
      for (final event in eventsQuery.docs) {
        final eventId = event.id;
        // Calcular horas requeridas dinámicamente
        final requiredHours = await EventService.calculateTotalHours(eventId);
        if (requiredHours <= 0) continue;
        
        // Obtener registros del evento
        final registrationsQuery = await FirebaseFirestore.instance
            .collection('registrations')
            .where('baseEventId', isEqualTo: event.id)
            .get();
        
        for (final reg in registrationsQuery.docs) {
          final regData = reg.data();
          final userId = regData['userId'];
          
          // Verificar si ya tiene certificado
          final hasCertificate = certificatesQuery.docs.any((cert) {
            final certData = cert.data();
            return certData['userId'] == userId &&
                certData['baseEventId'] == event.id;
          });
          
          if (!hasCertificate) {
            // Contar horas confirmadas del usuario en este evento
            final userAttendanceQuery = await FirebaseFirestore.instance
                .collection('attendanceRecords')
                .where('userId', isEqualTo: userId)
                .where('baseEventId', isEqualTo: event.id)
                .where('status', isEqualTo: 'confirmed')
                .get();
            
            double userHours = 0;
            for (final att in userAttendanceQuery.docs) {
              final attData = att.data();
              userHours += (attData['hoursEarned'] ?? 0).toDouble();
            }
            
            if (userHours >= requiredHours) {
              pendingCertificates++;
            }
          }
        }
      }

      return {
        'activeUsers': users.length,
        'newUsers': newUsers,
        'activeEvents': eventsQuery.docs.length,
        'totalSubEvents': subEventsQuery.docs.length,
        'totalHours': totalHours.round(),
        'hoursThisPeriod': hoursThisPeriod.round(),
        'totalCertificates': certificatesQuery.docs.length,
        'pendingCertificates': pendingCertificates,
      };
    } catch (e) {
      debugPrint('Error en _getOverviewData: ${e.toString()}');
      return {};
    }
  }

  Future<Map<String, dynamic>> _getUserMetrics() async {
    try {
      final users = await UserService.getAllUsers();
      
      int students = 0;
      int coordinators = 0;
      int admins = 0;
      int usersWithHours = 0;

      for (final user in users) {
        switch (user.role) {
          case UserRole.estudiante:
            students++;
            break;
          case UserRole.coordinador:
            coordinators++;
            break;
          case UserRole.administrador:
            admins++;
            break;
        }
        
        if (user.totalHours > 0) {
          usersWithHours++;
        }
      }

      return {
        'totalUsers': users.length,
        'students': students,
        'coordinators': coordinators,
        'admins': admins,
        'usersWithHours': usersWithHours,
      };
    } catch (e) {
      debugPrint('Error en _getUserMetrics: ${e.toString()}');
      return {};
    }
  }

  Future<Map<String, dynamic>> _getEventMetrics() async {
    try {
      // Obtener todos los eventos
      final eventsQuery = await FirebaseFirestore.instance
          .collection('events')
          .get();
      
      int publishedEvents = 0;
      for (final doc in eventsQuery.docs) {
        if (doc.data()['status'] == 'publicado') {
          publishedEvents++;
        }
      }

      // Obtener todas las actividades
      final subEventsQuery = await FirebaseFirestore.instance
          .collection('subEvents')
          .get();
      
      final now = DateTime.now();
      int pastSubEvents = 0;
      int upcomingSubEvents = 0;

      for (final doc in subEventsQuery.docs) {
        final data = doc.data();
        final date = (data['date'] as Timestamp).toDate();
        
        if (date.isBefore(now)) {
          pastSubEvents++;
        } else {
          upcomingSubEvents++;
        }
      }

      return {
        'totalEvents': eventsQuery.docs.length,
        'publishedEvents': publishedEvents,
        'totalSubEvents': subEventsQuery.docs.length,
        'pastSubEvents': pastSubEvents,
        'upcomingSubEvents': upcomingSubEvents,
      };
    } catch (e) {
      debugPrint('Error en _getEventMetrics: ${e.toString()}');
      return {};
    }
  }

  Future<Map<String, dynamic>> _getAttendanceMetrics() async {
    try {
      final dateRange = _getDateRange();
      
      // Obtener todos los registros y filtrar en código
      final attendanceQuery = await FirebaseFirestore.instance
          .collection('attendanceRecords')
          .get();

      int confirmedRecords = 0;
      int pendingRecords = 0;
      int totalRecords = 0;
      double totalConfirmedHours = 0;

      for (final doc in attendanceQuery.docs) {
        final docData = doc.data() as Map<String, dynamic>?;
        if (docData == null) continue;
        
        // Filtrar por fecha si es necesario
        if (dateRange != null) {
          final checkInTime = docData['checkInTime'] as Timestamp?;
          if (checkInTime == null || checkInTime.toDate().isBefore(dateRange['start']!)) {
            continue;
          }
        }
        
        totalRecords++;
        final status = docData['status'];
        if (status == 'confirmed') {
          confirmedRecords++;
          totalConfirmedHours += (docData['hoursEarned'] ?? 0).toDouble();
        } else if (status == 'checkedIn') {
          pendingRecords++;
        }
      }

      final confirmationRate = totalRecords > 0
          ? (confirmedRecords / totalRecords) * 100
          : 0.0;

      return {
        'totalRecords': totalRecords,
        'confirmedRecords': confirmedRecords,
        'pendingRecords': pendingRecords,
        'totalConfirmedHours': totalConfirmedHours,
        'confirmationRate': confirmationRate,
      };
    } catch (e) {
      debugPrint('Error en _getAttendanceMetrics: ${e.toString()}');
      return {};
    }
  }

  Future<Map<String, dynamic>> _getCertificateMetrics() async {
    try {
      final dateRange = _getDateRange();
      
      // Obtener todos los certificados y filtrar en código
      final certificatesQuery = await FirebaseFirestore.instance
          .collection('certificates')
          .get();

      final uniqueStudents = <String>{};
      final programCounts = <String, int>{};
      int totalCertificates = 0;

      for (final doc in certificatesQuery.docs) {
        final docData = doc.data() as Map<String, dynamic>?;
        if (docData == null) continue;
        
        // Filtrar por fecha si es necesario
        if (dateRange != null) {
          final createdAt = docData['createdAt'] as Timestamp?;
          if (createdAt == null || createdAt.toDate().isBefore(dateRange['start']!)) {
            continue;
          }
        }
        
        totalCertificates++;
        final userId = docData['userId'] as String? ?? '';
        final eventId = docData['baseEventId'] as String? ?? '';
        
        if (userId.isNotEmpty) {
          uniqueStudents.add(userId);
        }
        if (eventId.isNotEmpty) {
          programCounts[eventId] = (programCounts[eventId] ?? 0) + 1;
        }
      }

      // Encontrar el programa con más certificados
      String topProgramId = '';
      int topProgramCount = 0;
      
      programCounts.forEach((eventId, certCount) {
        if (certCount > topProgramCount) {
          topProgramCount = certCount;
          topProgramId = eventId;
        }
      });

      String topProgramName = 'N/A';
      if (topProgramId.isNotEmpty) {
        try {
          final eventDoc = await FirebaseFirestore.instance
              .collection('events')
              .doc(topProgramId)
              .get();
          topProgramName = eventDoc.data()?['title'] ?? 'Desconocido';
        } catch (e) {
          topProgramName = 'Desconocido';
        }
      }

      return {
        'totalCertificates': totalCertificates,
        'uniqueStudents': uniqueStudents.length,
        'topProgramName': topProgramName,
        'topProgramCount': topProgramCount,
      };
    } catch (e) {
      debugPrint('Error en _getCertificateMetrics: ${e.toString()}');
      return {};
    }
  }

  Future<Map<String, dynamic>> _getTopPerformers() async {
    try {
      // Top estudiantes por horas - obtener todos y filtrar manualmente
      final usersQuery = await FirebaseFirestore.instance
          .collection('users')
          .get();

      // Filtrar y ordenar manualmente
      final studentsList = <Map<String, dynamic>>[];
      for (final doc in usersQuery.docs) {
        final data = doc.data();
        final role = data['role'] as String?;
        final hours = (data['totalHours'] ?? 0).toDouble();
        
        if (role == 'estudiante' && hours > 0) {
          studentsList.add({
            'name': data['displayName'] ?? 'Usuario',
            'photoURL': data['photoURL'] ?? '',
            'value': hours,
          });
        }
      }
      
      // Ordenar de mayor a menor
      studentsList.sort((a, b) => (b['value'] as double).compareTo(a['value'] as double));
      final topStudents = studentsList.take(10).toList();

      // Top coordinadores por número de eventos creados
      final eventsQuery = await FirebaseFirestore.instance
          .collection('events')
          .get();
      
      final coordinatorEventCounts = <String, Map<String, dynamic>>{};
      
      for (final doc in eventsQuery.docs) {
        final coordinatorId = doc.data()['coordinatorId'];
        if (coordinatorId != null) {
          if (!coordinatorEventCounts.containsKey(coordinatorId)) {
            // Obtener info del coordinador
            try {
              final userDoc = await FirebaseFirestore.instance
                  .collection('users')
                  .doc(coordinatorId)
                  .get();
              
              if (userDoc.exists) {
                final userData = userDoc.data()!;
                coordinatorEventCounts[coordinatorId] = {
                  'name': userData['displayName'] ?? 'Usuario',
                  'photoURL': userData['photoURL'] ?? '',
                  'value': 0,
                };
              }
            } catch (e) {
              // Ignorar errores al obtener usuario
            }
          }
          
          if (coordinatorEventCounts.containsKey(coordinatorId)) {
            coordinatorEventCounts[coordinatorId]!['value'] = 
                (coordinatorEventCounts[coordinatorId]!['value'] as int) + 1;
          }
        }
      }

      final topCoordinators = coordinatorEventCounts.values.toList()
        ..sort((a, b) => (b['value'] as int).compareTo(a['value'] as int));

      return {
        'topStudents': topStudents,
        'topCoordinators': topCoordinators.take(10).toList(),
      };
    } catch (e) {
      debugPrint('Error en _getTopPerformers: ${e.toString()}');
      return {
        'topStudents': [],
        'topCoordinators': [],
      };
    }
  }

  Map<String, DateTime>? _getDateRange() {
    final now = DateTime.now();
    
    switch (_selectedPeriod) {
      case 'week':
        return {
          'start': now.subtract(const Duration(days: 7)),
          'end': now,
        };
      case 'month':
        return {
          'start': DateTime(now.year, now.month, 1),
          'end': now,
        };
      case 'quarter':
        final quarterStart = DateTime(now.year, ((now.month - 1) ~/ 3) * 3 + 1, 1);
        return {
          'start': quarterStart,
          'end': now,
        };
      case 'year':
        return {
          'start': DateTime(now.year, 1, 1),
          'end': now,
        };
      case 'custom':
        return {
          'start': _selectedDate,
          'end': now,
        };
      case 'all':
      default:
        return null; // Sin filtro de fecha
    }
  }
}
