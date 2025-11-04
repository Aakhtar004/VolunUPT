import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/services.dart';

// Clase auxiliar para combinar registro con información del subevento
class RegistrationWithSubEvent {
  final RegistrationModel registration;
  final SubEventModel? subEvent;

  RegistrationWithSubEvent({required this.registration, this.subEvent});
}

class MyRegistrationsScreen extends StatefulWidget {
  final UserModel user;

  const MyRegistrationsScreen({super.key, required this.user});

  @override
  State<MyRegistrationsScreen> createState() => _MyRegistrationsScreenState();
}

class _MyRegistrationsScreenState extends State<MyRegistrationsScreen> {
  String _selectedFilter = 'all';

  Future<List<RegistrationWithSubEvent>> _loadRegistrationsWithSubEvents(
    List<RegistrationModel> registrations,
  ) async {
    final List<RegistrationWithSubEvent> result = [];

    for (final registration in registrations) {
      try {
        final subEvent = await EventService.getSubEventById(
          registration.subEventId,
        );
        result.add(
          RegistrationWithSubEvent(
            registration: registration,
            subEvent: subEvent,
          ),
        );
      } catch (e) {
        // Si no se puede cargar el subevento, agregar solo el registro
        result.add(
          RegistrationWithSubEvent(registration: registration, subEvent: null),
        );
      }
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Mis Inscripciones',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1E3A8A),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          _buildFilterTabs(),
          Expanded(
            child: StreamBuilder<List<RegistrationModel>>(
              stream: EventService.getUserRegistrations(widget.user.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF1E3A8A)),
                  );
                }

                if (snapshot.hasError) {
                  // Mostrar estado vacío cuando ocurra un error (p.ej., datos faltantes)
                  return _buildEmptyState();
                }

                final registrations = snapshot.data ?? [];

                return FutureBuilder<List<RegistrationWithSubEvent>>(
                  future: _loadRegistrationsWithSubEvents(registrations),
                  builder: (context, futureSnapshot) {
                    if (futureSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF1E3A8A),
                        ),
                      );
                    }

                    if (futureSnapshot.hasError) {
                      // También tratar los errores del Future como vacío
                      return _buildEmptyState();
                    }

                    final registrationsWithSubEvents =
                        futureSnapshot.data ?? [];
                    final filteredRegistrations = _filterRegistrations(
                      registrationsWithSubEvents,
                    );

                    if (filteredRegistrations.isEmpty) {
                      return _buildEmptyState();
                    }

                    return RefreshIndicator(
                      onRefresh: () async {
                        setState(() {});
                      },
                      color: const Color(0xFF1E3A8A),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredRegistrations.length,
                        itemBuilder: (context, index) {
                          return _buildRegistrationCard(
                            filteredRegistrations[index],
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildFilterChip('all', 'Todas', Icons.list),
          const SizedBox(width: 8),
          _buildFilterChip('upcoming', 'Próximas', Icons.schedule),
          const SizedBox(width: 8),
          _buildFilterChip('completed', 'Completadas', Icons.check_circle),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label, IconData icon) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isSelected ? Colors.white : const Color(0xFF1E3A8A),
          ),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
        });
      },
      selectedColor: const Color(0xFF1E3A8A),
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : const Color(0xFF1E3A8A),
        fontWeight: FontWeight.w500,
      ),
    );
  }

  List<RegistrationWithSubEvent> _filterRegistrations(
    List<RegistrationWithSubEvent> registrations,
  ) {
    switch (_selectedFilter) {
      case 'upcoming':
        return registrations
            .where(
              (reg) => reg.subEvent?.startTime.isAfter(DateTime.now()) ?? false,
            )
            .toList();
      case 'completed':
        return registrations
            .where(
              (reg) => reg.subEvent?.endTime.isBefore(DateTime.now()) ?? false,
            )
            .toList();
      default:
        return registrations;
    }
  }

  Widget _buildRegistrationCard(
    RegistrationWithSubEvent registrationWithSubEvent,
  ) {
    final registration = registrationWithSubEvent.registration;
    final subEvent = registrationWithSubEvent.subEvent;

    if (subEvent == null) {
      return Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Actividad no disponible',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Inscrito el ${_formatDate(registration.registeredAt)}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    final isUpcoming = subEvent.startTime.isAfter(DateTime.now());
    final isCompleted = subEvent.endTime.isBefore(DateTime.now());
    final isActive =
        DateTime.now().isAfter(subEvent.startTime) &&
        DateTime.now().isBefore(subEvent.endTime);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showRegistrationDetails(registrationWithSubEvent),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      subEvent.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ),
                  _buildStatusChip(isUpcoming, isActive, isCompleted),
                ],
              ),
              const SizedBox(height: 8),
              if (subEvent.location.isNotEmpty) ...[
                Text(
                  subEvent.location,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
              ],
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(subEvent.startTime),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${_formatTime(subEvent.startTime)} - ${_formatTime(subEvent.endTime)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
              if (subEvent.location.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        subEvent.location,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Inscrito: ${_formatDate(registration.registeredAt)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                  if (isUpcoming)
                    TextButton(
                      onPressed: () =>
                          _showUnregisterDialog(registrationWithSubEvent),
                      child: const Text(
                        'Cancelar inscripción',
                        style: TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(bool isUpcoming, bool isActive, bool isCompleted) {
    Color color;
    String text;
    IconData icon;

    if (isCompleted) {
      color = Colors.green;
      text = 'Completada';
      icon = Icons.check_circle;
    } else if (isActive) {
      color = Colors.orange;
      text = 'En curso';
      icon = Icons.play_circle;
    } else {
      color = Colors.blue;
      text = 'Próxima';
      icon = Icons.schedule;
    }

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
            text,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: color,
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
          Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No tienes inscripciones',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Explora los eventos disponibles y regístrate',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.explore),
            label: const Text('Explorar Eventos'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showRegistrationDetails(
    RegistrationWithSubEvent registrationWithSubEvent,
  ) {
    final registration = registrationWithSubEvent.registration;
    final subEvent = registrationWithSubEvent.subEvent;

    if (subEvent == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se puede mostrar información de esta actividad'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  subEvent.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (subEvent.location.isNotEmpty) ...[
                          const Text(
                            'Ubicación',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            subEvent.location,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        _buildDetailRow(
                          'Fecha',
                          _formatDate(subEvent.startTime),
                        ),
                        _buildDetailRow(
                          'Hora',
                          '${_formatTime(subEvent.startTime)} - ${_formatTime(subEvent.endTime)}',
                        ),
                        _buildDetailRow(
                          'Capacidad',
                          '${subEvent.registeredCount}/${subEvent.maxVolunteers}',
                        ),
                        _buildDetailRow(
                          'Inscrito el',
                          _formatDate(registration.registeredAt),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF6B7280),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, color: Color(0xFF1F2937)),
            ),
          ),
        ],
      ),
    );
  }

  void _showUnregisterDialog(
    RegistrationWithSubEvent registrationWithSubEvent,
  ) {
    final registration = registrationWithSubEvent.registration;
    final subEvent = registrationWithSubEvent.subEvent;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar inscripción'),
        content: Text(
          '¿Estás seguro de que quieres cancelar tu inscripción a "${subEvent?.title ?? 'esta actividad'}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _unregisterFromSubEvent(registration);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  Future<void> _unregisterFromSubEvent(RegistrationModel registration) async {
    try {
      await EventService.unregisterUserFromSubEvent(
        userId: widget.user.uid,
        subEventId: registration.subEventId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Inscripción cancelada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cancelar inscripción: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
