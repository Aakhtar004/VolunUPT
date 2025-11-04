import 'package:flutter/material.dart';
import '../../models/models.dart';
// Eliminado import de servicios: no se utiliza en esta pantalla

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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Reportes y Estadísticas',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF8B5CF6),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: () => _exportReports(),
            icon: const Icon(Icons.download),
            tooltip: 'Exportar Reportes',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildPeriodSelector(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
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
              color: Color(0xFF1F2937),
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
                  foregroundColor: const Color(0xFF8B5CF6),
                  side: const BorderSide(color: Color(0xFF8B5CF6)),
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
      selectedColor: const Color(0xFF8B5CF6),
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : const Color(0xFF8B5CF6),
        fontWeight: FontWeight.w500,
      ),
      backgroundColor: Colors.white,
      side: BorderSide(
        color: isSelected ? const Color(0xFF8B5CF6) : Colors.grey[300]!,
      ),
    );
  }

  Widget _buildOverviewCards() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _getOverviewData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
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
                color: Color(0xFF1F2937),
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
                  'Usuarios Activos',
                  data['activeUsers']?.toString() ?? '0',
                  Icons.people,
                  const Color(0xFF8B5CF6),
                  '+${data['newUsers'] ?? 0} nuevos',
                ),
                _buildOverviewCard(
                  'Eventos Activos',
                  data['activeEvents']?.toString() ?? '0',
                  Icons.event,
                  Colors.blue,
                  '${data['totalSubEvents'] ?? 0} actividades',
                ),
                _buildOverviewCard(
                  'Horas Voluntariado',
                  '${data['totalHours'] ?? 0}h',
                  Icons.access_time,
                  Colors.green,
                  '+${data['hoursThisPeriod'] ?? 0}h período',
                ),
                _buildOverviewCard(
                  'Certificados',
                  data['totalCertificates']?.toString() ?? '0',
                  Icons.card_membership,
                  Colors.orange,
                  '${data['pendingCertificates'] ?? 0} pendientes',
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
        final data = snapshot.data ?? {};
        
        return _buildMetricSection(
          'Métricas de Usuarios',
          Icons.people,
          [
            _buildMetricRow('Total de usuarios', data['totalUsers']?.toString() ?? '0'),
            _buildMetricRow('Estudiantes activos', data['activeStudents']?.toString() ?? '0'),
            _buildMetricRow('Coordinadores', data['coordinators']?.toString() ?? '0'),
            _buildMetricRow('Nuevos registros', data['newRegistrations']?.toString() ?? '0'),
            _buildMetricRow('Tasa de participación', '${data['participationRate'] ?? 0}%'),
          ],
        );
      },
    );
  }

  Widget _buildEventMetrics() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _getEventMetrics(),
      builder: (context, snapshot) {
        final data = snapshot.data ?? {};
        
        return _buildMetricSection(
          'Métricas de Eventos',
          Icons.event,
          [
            _buildMetricRow('Programas creados', data['totalEvents']?.toString() ?? '0'),
            _buildMetricRow('Actividades realizadas', data['completedSubEvents']?.toString() ?? '0'),
            _buildMetricRow('Actividades programadas', data['upcomingSubEvents']?.toString() ?? '0'),
            _buildMetricRow('Promedio de participantes', data['avgParticipants']?.toString() ?? '0'),
            _buildMetricRow('Tasa de ocupación', '${data['occupancyRate'] ?? 0}%'),
          ],
        );
      },
    );
  }

  Widget _buildAttendanceMetrics() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _getAttendanceMetrics(),
      builder: (context, snapshot) {
        final data = snapshot.data ?? {};
        
        return _buildMetricSection(
          'Métricas de Asistencia',
          Icons.check_circle,
          [
            _buildMetricRow('Asistencias registradas', data['totalAttendances']?.toString() ?? '0'),
            _buildMetricRow('Asistencias confirmadas', data['confirmedAttendances']?.toString() ?? '0'),
            _buildMetricRow('Asistencias pendientes', data['pendingAttendances']?.toString() ?? '0'),
            _buildMetricRow('Horas totales confirmadas', '${data['totalConfirmedHours'] ?? 0}h'),
            _buildMetricRow('Tasa de confirmación', '${data['confirmationRate'] ?? 0}%'),
          ],
        );
      },
    );
  }

  Widget _buildCertificateMetrics() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _getCertificateMetrics(),
      builder: (context, snapshot) {
        final data = snapshot.data ?? {};
        
        return _buildMetricSection(
          'Métricas de Certificados',
          Icons.card_membership,
          [
            _buildMetricRow('Certificados emitidos', data['totalCertificates']?.toString() ?? '0'),
            _buildMetricRow('Estudiantes certificados', data['certifiedStudents']?.toString() ?? '0'),
            _buildMetricRow('Certificados este período', data['certificatesThisPeriod']?.toString() ?? '0'),
            _buildMetricRow('Programa más certificado', data['topProgram'] ?? 'N/A'),
            _buildMetricRow('Promedio horas/certificado', '${data['avgHoursPerCertificate'] ?? 0}h'),
          ],
        );
      },
    );
  }

  Widget _buildTopPerformers() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _getTopPerformers(),
      builder: (context, snapshot) {
        final data = snapshot.data ?? {};
        final topStudents = data['topStudents'] as List<Map<String, dynamic>>? ?? [];
        final topCoordinators = data['topCoordinators'] as List<Map<String, dynamic>>? ?? [];
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Destacados del Período',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
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
                    Colors.blue,
                    topStudents,
                    'horas',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTopPerformersCard(
                    'Coordinadores Activos',
                    Icons.supervisor_account,
                    Colors.green,
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
                Icon(icon, color: const Color(0xFF8B5CF6), size: 24),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
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
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
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
              const Text(
                'No hay datos disponibles',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
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
                      child: Text(
                        performer['name']?.toString().substring(0, 1).toUpperCase() ?? 'U',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
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
                      '${performer['value'] ?? 0} $metric',
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
        content: Text('Funcionalidad de exportación próximamente'),
        backgroundColor: Color(0xFF8B5CF6),
      ),
    );
  }

  // Métodos para obtener datos (simulados)
  Future<Map<String, dynamic>> _getOverviewData() async {
    // Simular carga de datos
    await Future.delayed(const Duration(milliseconds: 500));
    
    return {
      'activeUsers': 245,
      'newUsers': 12,
      'activeEvents': 8,
      'totalSubEvents': 24,
      'totalHours': 1250,
      'hoursThisPeriod': 180,
      'totalCertificates': 89,
      'pendingCertificates': 5,
    };
  }

  Future<Map<String, dynamic>> _getUserMetrics() async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    return {
      'totalUsers': 245,
      'activeStudents': 220,
      'coordinators': 15,
      'newRegistrations': 12,
      'participationRate': 78,
    };
  }

  Future<Map<String, dynamic>> _getEventMetrics() async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    return {
      'totalEvents': 8,
      'completedSubEvents': 18,
      'upcomingSubEvents': 6,
      'avgParticipants': 28,
      'occupancyRate': 85,
    };
  }

  Future<Map<String, dynamic>> _getAttendanceMetrics() async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    return {
      'totalAttendances': 456,
      'confirmedAttendances': 398,
      'pendingAttendances': 58,
      'totalConfirmedHours': 1250,
      'confirmationRate': 87,
    };
  }

  Future<Map<String, dynamic>> _getCertificateMetrics() async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    return {
      'totalCertificates': 89,
      'certifiedStudents': 76,
      'certificatesThisPeriod': 15,
      'topProgram': 'Apoyo Educativo',
      'avgHoursPerCertificate': 25,
    };
  }

  Future<Map<String, dynamic>> _getTopPerformers() async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    return {
      'topStudents': [
        {'name': 'María González', 'value': 45},
        {'name': 'Carlos Ruiz', 'value': 38},
        {'name': 'Ana Pérez', 'value': 32},
        {'name': 'Luis Torres', 'value': 28},
        {'name': 'Sofia Mendoza', 'value': 25},
      ],
      'topCoordinators': [
        {'name': 'Dr. Roberto Silva', 'value': 5},
        {'name': 'Ing. Carmen López', 'value': 4},
        {'name': 'Lic. Miguel Herrera', 'value': 3},
        {'name': 'Dra. Patricia Vega', 'value': 2},
      ],
    };
  }
}