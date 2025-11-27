import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/services.dart';
import '../../utils/app_colors.dart';

// Clase para agrupar evento con sus subeventos inscritos
class EventWithRegistrations {
  final EventModel event;
  final List<RegistrationWithSubEvent> registrations;

  EventWithRegistrations({required this.event, required this.registrations});
}

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

  Future<List<EventWithRegistrations>> _loadGroupedRegistrations(
    List<RegistrationModel> registrations,
  ) async {
    // Agrupar registros por baseEventId
    final Map<String, List<RegistrationModel>> groupedByEvent = {};

    for (final registration in registrations) {
      if (!groupedByEvent.containsKey(registration.baseEventId)) {
        groupedByEvent[registration.baseEventId] = [];
      }
      groupedByEvent[registration.baseEventId]!.add(registration);
    }

    // Cargar información de eventos y subeventos
    final List<EventWithRegistrations> result = [];

    for (final entry in groupedByEvent.entries) {
      try {
        final event = await EventService.getEventById(entry.key);
        if (event == null) continue;

        final List<RegistrationWithSubEvent> regsWithSubEvents = [];

        for (final reg in entry.value) {
          SubEventModel? subEvent;
          if (reg.subEventId.isNotEmpty) {
            try {
              subEvent = await EventService.getSubEventById(reg.subEventId);
            } catch (e) {
              // Ignorar si no se puede cargar el subevento
            }
          }
          regsWithSubEvents.add(
            RegistrationWithSubEvent(registration: reg, subEvent: subEvent),
          );
        }

        result.add(
          EventWithRegistrations(
            event: event,
            registrations: regsWithSubEvents,
          ),
        );
      } catch (e) {
        // Ignorar eventos que no se pueden cargar
      }
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text(
          'Mis Inscripciones',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: false,
        backgroundColor: AppColors.primary,
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
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }

                if (snapshot.hasError || !snapshot.hasData) {
                  return _buildEmptyState();
                }

                final registrations = snapshot.data ?? [];

                if (registrations.isEmpty) {
                  return _buildEmptyState();
                }

                return FutureBuilder<List<EventWithRegistrations>>(
                  future: _loadGroupedRegistrations(registrations),
                  builder: (context, futureSnapshot) {
                    if (futureSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      );
                    }

                    if (futureSnapshot.hasError || !futureSnapshot.hasData) {
                      return _buildEmptyState();
                    }

                    final eventsWithRegistrations = futureSnapshot.data ?? [];

                    if (eventsWithRegistrations.isEmpty) {
                      return _buildEmptyState();
                    }

                    // Calcular estadísticas
                    int upcomingCount = 0;
                    int activeCount = 0;
                    int completedCount = 0;
                    final now = DateTime.now();

                    for (final eventGroup in eventsWithRegistrations) {
                      for (final reg in eventGroup.registrations) {
                        if (reg.subEvent != null) {
                          if (reg.subEvent!.startTime.isAfter(now)) {
                            upcomingCount++;
                          } else if (now.isBefore(reg.subEvent!.endTime)) {
                            activeCount++;
                          } else {
                            completedCount++;
                          }
                        }
                      }
                    }

                    final filteredEvents = _filterEvents(
                      eventsWithRegistrations,
                    );

                    return RefreshIndicator(
                      onRefresh: () async {
                        setState(() {});
                      },
                      color: AppColors.primary,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          // Tarjetas de resumen
                          Row(
                            children: [
                              Expanded(
                                child: _buildSummaryCard(
                                  label: 'Próximas',
                                  value: upcomingCount.toString(),
                                  color: AppColors.primary,
                                  icon: Icons.schedule_rounded,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildSummaryCard(
                                  label: 'En curso',
                                  value: activeCount.toString(),
                                  color: AppColors.accent,
                                  icon: Icons.play_circle_rounded,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildSummaryCard(
                                  label: 'Finalizadas',
                                  value: completedCount.toString(),
                                  color: AppColors.success,
                                  icon: Icons.check_circle_rounded,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Lista de eventos (programas)
                          ...filteredEvents.map(
                            (eventGroup) => _buildEventCard(eventGroup),
                          ),
                        ],
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('all', 'Todas', Icons.list_rounded),
            const SizedBox(width: 8),
            _buildFilterChip('upcoming', 'Próximas', Icons.schedule_rounded),
            const SizedBox(width: 8),
            _buildFilterChip('active', 'En curso', Icons.play_circle_rounded),
            const SizedBox(width: 8),
            _buildFilterChip(
              'completed',
              'Finalizadas',
              Icons.check_circle_rounded,
            ),
          ],
        ),
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
            color: isSelected ? Colors.white : AppColors.primary,
          ),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
        });
      },
      selectedColor: AppColors.primary,
      backgroundColor: Colors.white,
      checkmarkColor: Colors.white,
      side: BorderSide(
        color: isSelected ? AppColors.primary : Colors.grey.shade300,
        width: 1,
      ),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.textPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  List<EventWithRegistrations> _filterEvents(
    List<EventWithRegistrations> events,
  ) {
    if (_selectedFilter == 'all') return events;

    final now = DateTime.now();

    return events.where((eventGroup) {
      final hasMatchingSubEvents = eventGroup.registrations.any((reg) {
        if (reg.subEvent == null) return false;

        switch (_selectedFilter) {
          case 'upcoming':
            return reg.subEvent!.startTime.isAfter(now);
          case 'active':
            return now.isAfter(reg.subEvent!.startTime) &&
                now.isBefore(reg.subEvent!.endTime);
          case 'completed':
            return reg.subEvent!.endTime.isBefore(now);
          default:
            return true;
        }
      });

      return hasMatchingSubEvents;
    }).toList();
  }

  Widget _buildEventCard(EventWithRegistrations eventGroup) {
    final event = eventGroup.event;
    final registrations = eventGroup.registrations;
    final now = DateTime.now();

    // Contar estados de los subeventos
    int upcomingCount = 0;
    int activeCount = 0;
    int completedCount = 0;

    for (final reg in registrations) {
      if (reg.subEvent != null) {
        if (reg.subEvent!.startTime.isAfter(now)) {
          upcomingCount++;
        } else if (now.isBefore(reg.subEvent!.endTime)) {
          activeCount++;
        } else {
          completedCount++;
        }
      }
    }

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: InkWell(
        onTap: () => _showSubEventsModal(eventGroup),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.event_note_rounded,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${registrations.length} ${registrations.length == 1 ? 'actividad inscrita' : 'actividades inscritas'}',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.grey.shade400,
                    size: 24,
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Mini estadísticas
              Row(
                children: [
                  if (upcomingCount > 0) ...[
                    _buildMiniStat(
                      upcomingCount.toString(),
                      'Próximas',
                      AppColors.primary,
                      Icons.schedule_rounded,
                    ),
                    const SizedBox(width: 12),
                  ],
                  if (activeCount > 0) ...[
                    _buildMiniStat(
                      activeCount.toString(),
                      'En curso',
                      AppColors.accent,
                      Icons.play_circle_rounded,
                    ),
                    const SizedBox(width: 12),
                  ],
                  if (completedCount > 0)
                    _buildMiniStat(
                      completedCount.toString(),
                      'Finalizadas',
                      AppColors.success,
                      Icons.check_circle_rounded,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniStat(
    String value,
    String label,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.event_busy_rounded,
                size: 64,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No tienes inscripciones',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Explora los eventos disponibles\ny regístrate en las actividades',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.explore_rounded),
              label: const Text('Explorar Eventos'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSubEventsModal(EventWithRegistrations eventGroup) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                // Handle
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.event_note_rounded,
                          color: AppColors.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              eventGroup.event.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              '${eventGroup.registrations.length} ${eventGroup.registrations.length == 1 ? 'actividad' : 'actividades'}',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1),

                // Lista de subeventos
                Expanded(
                  child: ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.all(20),
                    itemCount: eventGroup.registrations.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final regWithSubEvent = eventGroup.registrations[index];
                      return _buildSubEventCard(regWithSubEvent);
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSubEventCard(RegistrationWithSubEvent regWithSubEvent) {
    final subEvent = regWithSubEvent.subEvent;
    final registration = regWithSubEvent.registration;

    if (subEvent == null) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: const Text(
            'Actividad no disponible',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    final now = DateTime.now();
    final isUpcoming = subEvent.startTime.isAfter(now);
    final isActive =
        now.isAfter(subEvent.startTime) && now.isBefore(subEvent.endTime);
    final isCompleted = subEvent.endTime.isBefore(now);

    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (isCompleted) {
      statusColor = AppColors.success;
      statusText = 'Finalizada';
      statusIcon = Icons.check_circle_rounded;
    } else if (isActive) {
      statusColor = AppColors.accent;
      statusText = 'En curso';
      statusIcon = Icons.play_circle_rounded;
    } else {
      statusColor = AppColors.primary;
      statusText = 'Próxima';
      statusIcon = Icons.schedule_rounded;
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: statusColor.withValues(alpha: 0.3), width: 1.5),
      ),
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
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 14, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Fecha y hora
            Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  _formatDate(subEvent.startTime),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.access_time_rounded,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  '${_formatTime(subEvent.startTime)} - ${_formatTime(subEvent.endTime)}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),

            if (subEvent.location.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.location_on_rounded,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      subEvent.location,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Acciones
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Inscrito: ${_formatDate(registration.registeredAt)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
                if (isUpcoming)
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _showUnregisterDialog(regWithSubEvent);
                    },
                    icon: const Icon(Icons.cancel_rounded, size: 16),
                    label: const Text('Cancelar'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.error,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showUnregisterDialog(RegistrationWithSubEvent regWithSubEvent) {
    final subEvent = regWithSubEvent.subEvent;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Cancelar inscripción',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          '¿Estás seguro de que quieres cancelar tu inscripción a "${subEvent?.title ?? 'esta actividad'}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Volver'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _unregisterFromSubEvent(regWithSubEvent.registration);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
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
          SnackBar(
            content: const Text('Inscripción cancelada exitosamente'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('No se pudo cancelar la inscripción'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
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
