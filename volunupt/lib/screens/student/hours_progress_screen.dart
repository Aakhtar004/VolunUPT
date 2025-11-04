import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/services.dart';

class HoursProgressScreen extends StatefulWidget {
  final UserModel user;

  const HoursProgressScreen({
    super.key,
    required this.user,
  });

  @override
  State<HoursProgressScreen> createState() => _HoursProgressScreenState();
}

class _HoursProgressScreenState extends State<HoursProgressScreen> {
  Map<String, dynamic> _stats = {};
  List<EventModel> _eligibleEvents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProgressData();
  }

  Future<void> _loadProgressData() async {
    setState(() => _isLoading = true);
    
    try {
      final stats = await HistoryService.getUserAttendanceStats(widget.user.uid);
      final eligibleEvents = await CertificateService.getEligibleEventsForUser(widget.user.uid);
      
      setState(() {
        _stats = stats;
        // Convertir la lista de mapas a solo la lista de eventos
        _eligibleEvents = eligibleEvents
            .map((item) => item['event'] as EventModel)
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar datos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Progreso de Horas',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF1E3A8A),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: _loadProgressData,
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF1E3A8A),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadProgressData,
              color: const Color(0xFF1E3A8A),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildOverviewCard(),
                    const SizedBox(height: 20),
                    _buildMonthlyProgressCard(),
                    const SizedBox(height: 20),
                    _buildCertificationProgressCard(),
                    const SizedBox(height: 20),
                    _buildRecentActivitiesCard(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildOverviewCard() {
    final totalHours = _stats['totalHours'] ?? 0;
    final confirmedHours = _stats['confirmedHours'] ?? 0;
    final pendingHours = _stats['pendingHours'] ?? 0;
    final totalActivities = _stats['totalActivities'] ?? 0;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Resumen General',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Total de Horas',
                    totalHours.toString(),
                    Icons.access_time,
                    Colors.white,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Actividades',
                    totalActivities.toString(),
                    Icons.event,
                    Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Confirmadas',
                    confirmedHours.toString(),
                    Icons.check_circle,
                    Colors.green[300]!,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Pendientes',
                    pendingHours.toString(),
                    Icons.schedule,
                    Colors.orange[300]!,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color iconColor) {
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.8),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildMonthlyProgressCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.trending_up, color: Color(0xFF1E3A8A)),
                const SizedBox(width: 8),
                const Text(
                  'Progreso Mensual',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _getMonthlyProgress(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                final monthlyData = snapshot.data ?? [];
                
                if (monthlyData.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text('No hay datos disponibles'),
                    ),
                  );
                }

                return Column(
                  children: monthlyData.map((data) {
                    return _buildMonthProgressBar(
                      data['month'] as String,
                      data['hours'] as int,
                      data['maxHours'] as int,
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthProgressBar(String month, int hours, int maxHours) {
    final progress = maxHours > 0 ? hours / maxHours : 0.0;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                month,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '$hours h',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3A8A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            backgroundColor: Colors.grey[200],
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1E3A8A)),
          ),
        ],
      ),
    );
  }

  Widget _buildCertificationProgressCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.card_membership, color: Color(0xFF10B981)),
                const SizedBox(width: 8),
                const Text(
                  'Progreso hacia Certificados',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_eligibleEvents.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'No hay programas de certificación disponibles',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ...(_eligibleEvents.map((event) => _buildCertificationProgress(event))),
          ],
        ),
      ),
    );
  }

  Widget _buildCertificationProgress(EventModel event) {
    return FutureBuilder<double>(
      future: _getUserHoursForEvent(event.eventId),
      builder: (context, snapshot) {
        final userHours = snapshot.data ?? 0.0;
        final requiredHours = event.totalHoursForCertificate;
        final progress = requiredHours > 0 ? userHours / requiredHours : 0.0;
        final isCompleted = userHours >= requiredHours;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[200]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      event.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (isCompleted)
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 20,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$userHours / $requiredHours horas',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  isCompleted ? Colors.green : const Color(0xFF10B981),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRecentActivitiesCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.history, color: Color(0xFFF59E0B)),
                    const SizedBox(width: 8),
                    const Text(
                      'Actividades Recientes',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Ver todas'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: HistoryService.getUserDetailedHistory(widget.user.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                final activities = (snapshot.data ?? []).take(3).toList();
                
                if (activities.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text('No hay actividades recientes'),
                    ),
                  );
                }

                return Column(
                  children: activities.map((activity) {
                    return _buildRecentActivityItem(activity);
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivityItem(Map<String, dynamic> activity) {
    final status = activity['status'] as String;
    final hours = activity['hours'] as int;
    final subEventName = activity['subEventName'] as String;
    final eventName = activity['eventName'] as String;
    final date = DateTime.parse(activity['date'] as String);

    Color statusColor;
    IconData statusIcon;
    
    switch (status) {
      case 'confirmed':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
        break;
      default:
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subEventName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  eventName,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$hours h',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3A8A),
                ),
              ),
              Text(
                _formatDate(date),
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _getMonthlyProgress() async {
    // Simulación de datos mensuales - en implementación real vendría del servicio
    final now = DateTime.now();
    final months = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun'];
    
    return List.generate(6, (index) {
      final monthIndex = (now.month - 6 + index) % 12;
      return {
        'month': months[monthIndex],
        'hours': (index + 1) * 5, // Datos simulados
        'maxHours': 20,
      };
    });
  }

  Future<double> _getUserHoursForEvent(String eventId) async {
    try {
      return await CertificateService.getUserTotalHoursForEvent(widget.user.uid, eventId);
    } catch (e) {
      return 0.0;
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    return '${date.day} ${months[date.month - 1]}';
  }
}