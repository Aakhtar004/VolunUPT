import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/services.dart';
import '../../utils/app_colors.dart';
import '../../utils/ui_feedback.dart';
import '../../utils/skeleton_loader.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Eventos Disponibles'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<EventModel>>(
        stream: EventService.getActiveEvents(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 3,
              itemBuilder: (context, index) => const EventCardSkeleton(),
            );
          }

          if (snapshot.hasError) {
            // Tratar el error como estado vacío contextual
            return _buildEmptyState();
          }

          final allEvents = snapshot.data ?? [];

          if (allEvents.isEmpty) {
            return _buildEmptyState();
          }

          // Filtrar eventos donde el usuario ya está inscrito
          final user = AuthService.currentUser;
          if (user == null) {
            // Si no hay usuario, mostrar todos los eventos
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: allEvents.length,
              itemBuilder: (context, index) {
                final event = allEvents[index];
                return _buildEventCard(event);
              },
            );
          }

          // Obtener registros del usuario para filtrar
          return StreamBuilder<List<RegistrationModel>>(
            stream: EventService.getUserRegistrations(user.uid),
            builder: (context, regSnapshot) {
              if (regSnapshot.connectionState == ConnectionState.waiting) {
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: 3,
                  itemBuilder: (context, index) => const EventCardSkeleton(),
                );
              }

              final registrations = regSnapshot.data ?? [];
              
              // Obtener IDs de eventos inscritos
              final registeredEventIds = registrations
                  .map((reg) => reg.baseEventId)
                  .toSet();

              // Filtrar eventos no inscritos
              final availableEvents = allEvents
                  .where((event) => !registeredEventIds.contains(event.eventId))
                  .toList();

              if (availableEvents.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_circle_rounded,
                            size: 64,
                            color: AppColors.success,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          '¡Estás inscrito en todos los eventos!',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Revisa tus inscripciones en "Mis Inscripciones"',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: availableEvents.length,
                itemBuilder: (context, index) {
                  final event = availableEvents[index];
                  return _buildEventCard(event);
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEventCard(EventModel event) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showEventDetails(event),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen del evento
            if (event.imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: Image.network(
                  event.imageUrl,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      color: Colors.grey[300],
                      child: const Icon(
                        Icons.image_not_supported,
                        size: 50,
                        color: Colors.grey,
                      ),
                    );
                  },
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título del evento
                  Text(
                    event.title,
                    style:
                        Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ) ??
                        const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),

                  // Descripción
                  Text(
                    event.description,
                    style:
                        Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[700],
                        ) ??
                        TextStyle(fontSize: 14, color: Colors.grey[700]),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),

                  // Información adicional
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${event.totalHoursForCertificate} horas para certificado',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Estado del evento (runtime)
                  StreamBuilder<List<SubEventModel>>(
                    stream: EventService.getSubEventsByEvent(event.eventId),
                    builder: (context, subSnap) {
                      final now = DateTime.now();
                      String label = _getStatusText(event.status);
                      Color color = _getStatusColor(event.status);
                      if (subSnap.hasData && subSnap.data!.isNotEmpty) {
                        final subs = subSnap.data!;
                        final hasStarted = subs.any((s) => !s.endTime.isBefore(now) && s.startTime.isBefore(now));
                        final hasCompleted = subs.every((s) => s.endTime.isBefore(now));
                        if (hasCompleted) {
                          label = 'Finalizado';
                          color = Colors.grey;
                        } else if (hasStarted) {
                          label = 'En curso';
                          color = AppColors.accent;
                        } else {
                          label = 'Pendiente';
                          color = AppColors.primary;
                        }
                      }
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
                        child: Text(
                          label,
                          style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w500),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No hay eventos disponibles',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Los eventos aparecerán aquí cuando estén disponibles',
            style: TextStyle(fontSize: 14, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(EventStatus status) {
    switch (status) {
      case EventStatus.borrador:
        return Colors.grey;
      case EventStatus.publicado:
        return AppColors.success;
      case EventStatus.completado:
        return AppColors.primary;
      case EventStatus.archivado:
        return AppColors.accent;
    }
  }

  String _getStatusText(EventStatus status) {
    switch (status) {
      case EventStatus.borrador:
        return 'Borrador';
      case EventStatus.publicado:
        return 'Publicado';
      case EventStatus.completado:
        return 'Completado';
      case EventStatus.archivado:
        return 'Archivado';
    }
  }

  void _showEventDetails(EventModel event) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
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

                // Título
                Text(
                  event.title,
                  style:
                      Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ) ??
                      const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),

                // Descripción completa
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Descripción',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                color: AppColors.textPrimary,
                              ) ??
                              TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          event.description,
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 20),

                        Text(
                          'Información del evento',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                color: AppColors.textPrimary,
                              ) ??
                              TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                        ),
                        const SizedBox(height: 8),

                        _buildInfoRow(
                          Icons.access_time,
                          'Horas requeridas para certificado',
                          '${event.totalHoursForCertificate} horas',
                        ),
                        _buildInfoRow(
                          Icons.info,
                          'Estado',
                          _getStatusText(event.status),
                        ),

                        const SizedBox(height: 20),

                        // Inscripción al programa
                        if (AuthService.currentUser != null)
                          FutureBuilder<Map<String, bool>>(
                            future: () async {
                              final uid = AuthService.currentUser!.uid;
                              final isReg = await EventService.isUserRegisteredForEvent(uid, event.eventId);
                              final started = await EventService.hasEventStarted(event.eventId);
                              final completed = await EventService.hasEventCompleted(event.eventId);
                              return {
                                'isRegistered': isReg,
                                'locked': started || completed,
                                'completed': completed,
                                'started': started,
                              };
                            }(),
                            builder: (context, snap) {
                              final data = snap.data ?? {};
                              final isRegistered = data['isRegistered'] == true;
                              final locked = data['locked'] == true;
                              final started = data['started'] == true;
                              final completed = data['completed'] == true;
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: locked
                                          ? null
                                          : () {
                                              if (isRegistered) {
                                                _unregisterFromEvent(event);
                                              } else {
                                                _registerToEvent(event);
                                              }
                                            },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: isRegistered
                                            ? AppColors.error
                                            : AppColors.primary,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: Text(
                                        isRegistered
                                            ? 'Cancelar inscripción al programa'
                                            : 'Inscribirme al programa',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  if (locked)
                                    Text(
                                      completed
                                          ? 'Inscripción cerrada: programa finalizado'
                                          : started
                                              ? 'Inscripción cerrada: programa en curso'
                                              : 'Inscripción cerrada',
                                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                  const SizedBox(height: 6),
                                ],
                              );
                            },
                          ),

                        // Botón para ver actividades
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _showSubEvents(event);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Ver actividades disponibles'),
                          ),
                        ),
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

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style:
                Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]) ??
                TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          Expanded(
            child: Text(
              value,
              style:
                  Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ) ??
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  void _showSubEvents(EventModel event) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
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

                // Título
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Actividades - ${event.title}',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ) ??
                            const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    StreamBuilder<List<RegistrationModel>>(
                      stream: EventService.getAllRegistrationsByEvent(event.eventId),
                      builder: (context, regSnap) {
                        final count = regSnap.data?.length ?? 0;
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.groups, size: 14, color: AppColors.primary),
                              const SizedBox(width: 6),
                              Text(
                                '$count inscritos',
                                style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Filtros y lista de subeventos
                Expanded(
                  child: FutureBuilder<Map<String, dynamic>>(
                    future: () async {
                      final user = AuthService.currentUser;
                      final regEvent = user != null
                          ? await EventService.isUserRegisteredForEvent(
                              user.uid,
                              event.eventId,
                            )
                          : false;
                      final subRegs = user != null
                          ? await EventService.getUserSubEventRegistrationsForEvent(
                              userId: user.uid,
                              baseEventId: event.eventId,
                            )
                          : <RegistrationModel>[];
                      return {
                        'registeredEvent': regEvent,
                        'registeredSubIds': subRegs
                            .map((r) => r.subEventId)
                            .toSet(),
                      };
                    }(),
                    builder: (context, preSnap) {
                      final registeredEvent =
                          (preSnap.data ?? {})['registeredEvent'] == true;
                      final registeredSubIds =
                          (preSnap.data ?? {})['registeredSubIds']
                              as Set<String>? ??
                          {};
                      return StreamBuilder<List<SubEventModel>>(
                        stream: EventService.getSubEventsByEvent(event.eventId),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          if (snapshot.hasError) {
                            // Tratar el error como estado vacío para actividades
                            return const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.event_busy,
                                    size: 64,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'No hay actividades disponibles',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          final subEvents = snapshot.data ?? [];

                          if (subEvents.isEmpty) {
                            return const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.event_busy,
                                    size: 64,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'No hay actividades disponibles',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                          // Filtro en estado local
                          return StatefulBuilder(
                            builder: (context, setFilter) {
                              String filter = 'all';
                              int totalCount = subEvents.length;
                              final now = DateTime.now();
                              final inscritasCount = subEvents
                                  .where((s) => registeredSubIds.contains(s.subEventId))
                                  .length;
                              final disponiblesCount = subEvents
                                  .where((s) {
                                    final isFull = s.registeredCount >= s.maxVolunteers;
                                    final hasEnded = s.endTime.isBefore(now);
                                    final hasStarted = !hasEnded && s.startTime.isBefore(now);
                                    final isRegSub = registeredSubIds.contains(s.subEventId);
                                    return !hasStarted && !hasEnded && !isFull && !isRegSub;
                                  })
                                  .length;

                              Widget filterBar() {
                                return Row(
                                  children: [
                                    FilterChip(
                                      selected: filter == 'all',
                                      label: Text('Todas ($totalCount)'),
                                      onSelected: (_) =>
                                          setFilter(() => filter = 'all'),
                                    ),
                                    const SizedBox(width: 8),
                                    FilterChip(
                                      selected: filter == 'inscritas',
                                      label: Text('Inscritas ($inscritasCount)'),
                                      onSelected: (_) =>
                                          setFilter(() => filter = 'inscritas'),
                                    ),
                                    const SizedBox(width: 8),
                                    FilterChip(
                                      selected: filter == 'disponibles',
                                      label: Text('Disponibles ($disponiblesCount)'),
                                      onSelected: (_) => setFilter(
                                        () => filter = 'disponibles',
                                      ),
                                    ),
                                  ],
                                );
                              }

                              List<SubEventModel> filtered = subEvents.where((
                                s,
                              ) {
                                final isFull =
                                    s.registeredCount >= s.maxVolunteers;
                                final now = DateTime.now();
                                final hasEnded = s.endTime.isBefore(now);
                                final hasStarted = !hasEnded && s.startTime.isBefore(now);
                                final isRegSub = registeredSubIds.contains(
                                  s.subEventId,
                                );
                                switch (filter) {
                                  case 'inscritas':
                                    return isRegSub;
                                  case 'disponibles':
                                    return !hasStarted && !hasEnded && !isFull && !isRegSub;
                                  default:
                                    return true;
                                }
                              }).toList();

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  filterBar(),
                                  const SizedBox(height: 12),
                                  Expanded(
                                    child: ListView.builder(
                                      controller: scrollController,
                                      itemCount: filtered.length,
                                      itemBuilder: (context, index) {
                                        final subEvent = filtered[index];
                                        return _buildSubEventCard(
                                          subEvent,
                                          registeredEvent: registeredEvent,
                                          isRegisteredToSub: registeredSubIds
                                              .contains(subEvent.subEventId),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      );
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

  Widget _buildSubEventCard(
    SubEventModel subEvent, {
    bool registeredEvent = false,
    bool isRegisteredToSub = false,
  }) {
    final isEventFull = subEvent.registeredCount >= subEvent.maxVolunteers;
    final now = DateTime.now();
    final isFinalized = subEvent.endTime.isBefore(now);
    final isStarted = !isFinalized && subEvent.startTime.isBefore(now);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título y estado
            Row(
              children: [
                Expanded(
                  child: Text(
                    subEvent.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (isRegisteredToSub)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Inscrito',
                      style: TextStyle(
                        color: AppColors.success,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                if (registeredEvent)
                  Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Programa',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                if (isFinalized)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Finalizado',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                else if (isStarted)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'En curso',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                else if (isEventFull)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Lleno',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            // Información del evento
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  _formatDate(subEvent.date),
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  '${_formatTime(subEvent.startTime)} - ${_formatTime(subEvent.endTime)}',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 4),

            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    subEvent.location,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Capacidad
            Row(
              children: [
                const Icon(Icons.people, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  '${subEvent.registeredCount}/${subEvent.maxVolunteers} inscritos',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Mensaje informativo: la inscripción es automática al inscribirse en el programa
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: registeredEvent
                    ? AppColors.success.withValues(alpha: 0.1)
                    : AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: registeredEvent
                      ? AppColors.success.withValues(alpha: 0.3)
                      : AppColors.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    registeredEvent ? Icons.check_circle : Icons.info_outline,
                    color: registeredEvent ? AppColors.success : AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      registeredEvent
                          ? 'Ya estás inscrito en esta actividad a través del programa'
                          : 'Inscríbete al programa para participar en todas sus actividades',
                      style: TextStyle(
                        fontSize: 13,
                        color: registeredEvent ? AppColors.success : AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
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

  Future<void> _registerToEvent(EventModel event) async {
    final currentUser = AuthService.currentUser;
    if (currentUser == null) return;

    // Primero obtenemos todas las actividades del programa
    final subEvents = await EventService.getSubEventsByEvent(event.eventId).first;
    final availableActivities = subEvents.where((s) {
      final now = DateTime.now();
      final hasStarted = s.startTime.isBefore(now);
      final hasEnded = s.endTime.isBefore(now);
      final isFull = s.registeredCount >= s.maxVolunteers;
      return !hasStarted && !hasEnded && !isFull;
    }).toList();

    if (!mounted) return;
    final ctx = context;

    try {
      final confirmed = await showDialog<bool>(
        // ignore: use_build_context_synchronously
        context: ctx,
        builder: (context) => AlertDialog(
          title: const Text('Inscribirme al programa'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('¿Deseas inscribirte al programa "${event.title}"?'),
              if (availableActivities.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Te inscribirás automáticamente en ${availableActivities.length} ${availableActivities.length == 1 ? "actividad disponible" : "actividades disponibles"}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('Inscribirme'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        // Mostrar diálogo de cargando
        if (!mounted) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => PopScope(
            canPop: false,
            child: const Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Inscribiendo...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );

        try {
          // Inscribirse al programa
          await EventService.registerUserToEvent(
            userId: currentUser.uid,
            baseEventId: event.eventId,
          );

          // Inscribirse automáticamente a todas las actividades disponibles
          int successCount = 0;
          for (final subEvent in availableActivities) {
            try {
              await EventService.registerUserToSubEvent(
                userId: currentUser.uid,
                subEventId: subEvent.subEventId,
                baseEventId: event.eventId,
              );
              successCount++;
            } catch (e) {
              // Si falla alguna actividad individual, continuamos con las demás
              // Error al inscribir en actividad: $e
            }
          }

          if (!mounted) return;
          Navigator.of(context).pop(); // Cerrar diálogo de cargando

          // Mostrar mensaje de éxito
          String message = 'Te has inscrito al programa "${event.title}"';
          if (successCount > 0) {
            message += ' y en $successCount ${successCount == 1 ? "actividad" : "actividades"}';
          }

          UiFeedback.showSuccess(context, message);
          Navigator.of(context).pop(); // Cerrar modal de detalles
        } catch (e) {
          if (!mounted) return;
          Navigator.of(context).pop(); // Cerrar diálogo de cargando
          
          UiFeedback.showError(
            context,
            'Ocurrió un error al inscribirte. Inténtalo nuevamente.',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        UiFeedback.showError(
          context,
          'Ocurrió un error al inscribirte. Inténtalo nuevamente.',
        );
      }
    }
  }

  Future<void> _unregisterFromEvent(EventModel event) async {
    final currentUser = AuthService.currentUser;
    if (currentUser == null) return;

    // Obtener las actividades en las que está inscrito
    final userSubRegs = await EventService.getUserSubEventRegistrationsForEvent(
      userId: currentUser.uid,
      baseEventId: event.eventId,
    );

    if (!mounted) return;
    final ctx = context;

    try {
      final confirmed = await showDialog<bool>(
        // ignore: use_build_context_synchronously
        context: ctx,
        builder: (context) => AlertDialog(
          title: const Text('Cancelar inscripción al programa'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '¿Estás seguro de que deseas cancelar tu inscripción al programa "${event.title}"?',
              ),
              if (userSubRegs.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.warning_amber,
                        color: AppColors.error,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'También se cancelará tu inscripción en ${userSubRegs.length} ${userSubRegs.length == 1 ? "actividad" : "actividades"}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('No'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              child: const Text('Sí, cancelar'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        // Mostrar diálogo de cargando
        if (!mounted) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => PopScope(
            canPop: false,
            child: const Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Cancelando inscripción...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );

        try {
          // Cancelar inscripción de todas las actividades primero
          for (final reg in userSubRegs) {
            try {
              await EventService.unregisterUserFromSubEvent(
                userId: currentUser.uid,
                subEventId: reg.subEventId,
              );
            } catch (e) {
              // Continuamos cancelando las demás
            }
          }

          // Luego cancelar la inscripción del programa
          await EventService.unregisterUserFromEvent(
            userId: currentUser.uid,
            baseEventId: event.eventId,
          );

          if (!mounted) return;
          Navigator.of(context).pop(); // Cerrar diálogo de cargando

          UiFeedback.showInfo(
            context,
            'Inscripción cancelada de "${event.title}"',
          );
          Navigator.of(context).pop(); // Cerrar modal de detalles
        } catch (e) {
          if (!mounted) return;
          Navigator.of(context).pop(); // Cerrar diálogo de cargando

          UiFeedback.showError(
            context,
            'Ocurrió un error al cancelar tu inscripción.',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        UiFeedback.showError(
          context,
          'Ocurrió un error al cancelar tu inscripción. Inténtalo nuevamente.',
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
