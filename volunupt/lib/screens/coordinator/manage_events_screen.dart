import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../utils/app_colors.dart';
import '../../models/models.dart';
import '../../services/services.dart';
import 'coordinator_student_qr_scanner_screen.dart';
import 'attendance_list_screen.dart';

class ManageEventsScreen extends StatefulWidget {
  final UserModel user;

  const ManageEventsScreen({super.key, required this.user});

  @override
  State<ManageEventsScreen> createState() => _ManageEventsScreenState();
}

class _ManageEventsScreenState extends State<ManageEventsScreen> {
  String _selectedTab = 'events';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text(
          'Gestionar Eventos',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: () => _showCreateEventDialog(),
            icon: const Icon(Icons.add),
            tooltip: 'Crear Evento',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(
            child: _selectedTab == 'events'
                ? _buildEventsTab()
                : _buildSubEventsTab(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton('events', 'Programas', Icons.event_note),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildTabButton('subevents', 'Actividades', Icons.event),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String value, String label, IconData icon) {
    final isSelected = _selectedTab == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey[300]!,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : AppColors.primary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventsTab() {
    return StreamBuilder<List<EventModel>>(
      stream: EventService.getEventsByCoordinator(widget.user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        if (snapshot.hasError) {
          // Mostrar estado vacío contextual cuando ocurra un error
          return _buildEmptyEventsState();
        }

        final events = snapshot.data ?? [];

        if (events.isEmpty) {
          return _buildEmptyEventsState();
        }

        return RefreshIndicator(
          onRefresh: () async => setState(() {}),
          color: AppColors.primary,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: events.length,
            itemBuilder: (context, index) {
              return _buildEventCard(events[index]);
            },
          ),
        );
      },
    );
  }

  Widget _buildSubEventsTab() {
    return StreamBuilder<List<SubEventModel>>(
      stream: EventService.getSubEventsByCoordinator(widget.user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        if (snapshot.hasError) {
          // Mostrar estado vacío contextual cuando ocurra un error
          return _buildEmptySubEventsState();
        }

        final subEvents = snapshot.data ?? [];

        if (subEvents.isEmpty) {
          return _buildEmptySubEventsState();
        }

        return RefreshIndicator(
          onRefresh: () async => setState(() {}),
          color: AppColors.primary,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: subEvents.length,
            itemBuilder: (context, index) {
              return _buildSubEventCard(subEvents[index]);
            },
          ),
        );
      },
    );
  }

  Widget _buildEventCard(EventModel event) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showEventDetails(event),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      event.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) => _handleEventAction(value, event),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 18),
                            SizedBox(width: 8),
                            Text('Editar'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: event.status == EventStatus.borrador ? 'publish' : 'mark_draft',
                        child: Row(
                          children: [
                            Icon(
                              event.status == EventStatus.borrador ? Icons.publish : Icons.unpublished,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(event.status == EventStatus.borrador ? 'Publicar' : 'Marcar como borrador'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'add_subevent',
                        child: Row(
                          children: [
                            Icon(Icons.add_circle, size: 18),
                            SizedBox(width: 8),
                            Text('Agregar Actividad'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'scan',
                        child: Row(
                          children: [
                            Icon(Icons.qr_code_scanner, size: 18),
                            SizedBox(width: 8),
                            Text('Pasar asistencia'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'stats',
                        child: Row(
                          children: [
                            Icon(Icons.analytics, size: 18),
                            SizedBox(width: 8),
                            Text('Estadísticas'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text(
                              'Eliminar',
                              style: TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (event.description.isNotEmpty) ...[
                Text(
                  event.description,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
              ],
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${event.totalHoursForCertificate} horas para certificado',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.event, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  FutureBuilder<int>(
                    future: _getSubEventCount(event.eventId),
                    builder: (context, snapshot) {
                      final count = snapshot.data ?? 0;
                      return Text(
                        '$count actividades',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(children: [_buildStatusChip(event.status), const Spacer()]),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: () => _showSelectSubEventForScan(event),
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Pasar asistencia'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubEventCard(SubEventModel subEvent) {
    final isUpcoming = subEvent.startTime.isAfter(DateTime.now());
    final isActive =
        DateTime.now().isAfter(subEvent.startTime) &&
        DateTime.now().isBefore(subEvent.endTime);
    final isCompleted = subEvent.endTime.isBefore(DateTime.now());

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showSubEventDetails(subEvent),
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
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) =>
                        _handleSubEventAction(value, subEvent),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 18),
                            SizedBox(width: 8),
                            Text('Editar'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'scan',
                        child: Row(
                          children: [
                            Icon(Icons.qr_code_scanner, size: 18),
                            SizedBox(width: 8),
                            Text('Pasar asistencia'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'attendance',
                        child: Row(
                          children: [
                            Icon(Icons.people, size: 18),
                            SizedBox(width: 8),
                            Text('Ver Asistencia'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text(
                              'Eliminar',
                              style: TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
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
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildSubEventStatusChip(isUpcoming, isActive, isCompleted),
                  const Spacer(),
                  Text(
                    '${subEvent.registeredCount}/${subEvent.maxVolunteers}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: () => _handleSubEventAction('scan', subEvent),
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Pasar asistencia'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(EventStatus status) {
    Color color;
    String text;
    IconData icon;

    switch (status) {
      case EventStatus.publicado:
        color = Colors.green;
        text = 'Publicado';
        icon = Icons.check_circle;
        break;
      case EventStatus.completado:
        color = Colors.blue;
        text = 'Completado';
        icon = Icons.check_circle;
        break;
      case EventStatus.archivado:
        color = Colors.grey;
        text = 'Archivado';
        icon = Icons.archive;
        break;
      case EventStatus.borrador:
        color = Colors.grey;
        text = 'Borrador';
        icon = Icons.edit;
        break;
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

  Widget _buildSubEventStatusChip(
    bool isUpcoming,
    bool isActive,
    bool isCompleted,
  ) {
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

  Widget _buildEmptyEventsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_note, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No tienes programas creados',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Crea tu primer programa de voluntariado',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showCreateEventDialog(),
            icon: const Icon(Icons.add),
            label: const Text('Crear Programa'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySubEventsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No tienes actividades creadas',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Las actividades aparecerán aquí una vez que las crees',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showCreateEventDialog() {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final hoursController = TextEditingController(text: '10');

    // Campos para sesión única
    final locationController = TextEditingController();
    final maxVolController = TextEditingController(text: '30');
    DateTime? singleDate;
    TimeOfDay? singleStart;
    TimeOfDay? singleEnd;
    bool isSingleSession = true; // por defecto

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          void pickDate() async {
            final now = DateTime.now();
            final picked = await showDatePicker(
              context: context,
              initialDate: now,
              firstDate: now.subtract(const Duration(days: 0)),
              lastDate: now.add(const Duration(days: 365 * 2)),
            );
            if (picked != null) {
              setStateDialog(() => singleDate = picked);
            }
          }

          void pickStartTime() async {
            final picked = await showTimePicker(
              context: context,
              initialTime: const TimeOfDay(hour: 9, minute: 0),
            );
            if (picked != null) {
              setStateDialog(() => singleStart = picked);
            }
          }

          void pickEndTime() async {
            final picked = await showTimePicker(
              context: context,
              initialTime: const TimeOfDay(hour: 12, minute: 0),
            );
            if (picked != null) {
              setStateDialog(() => singleEnd = picked);
            }
          }

          String formatTime(TimeOfDay? t) {
            if (t == null) return 'Seleccionar';
            final dt = DateTime(0, 1, 1, t.hour, t.minute);
            return DateFormat('HH:mm').format(dt);
          }

          return AlertDialog(
            title: const Text('Crear Programa'),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Título',
                        hintText: 'Nombre del programa',
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Ingresa un título'
                          : null,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Descripción',
                        hintText: 'Describe el programa',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: hoursController,
                      decoration: const InputDecoration(
                        labelText: 'Horas para certificado',
                        hintText: 'Ej. 20',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        final value = double.tryParse(v ?? '');
                        if (value == null || value <= 0) {
                          return 'Ingresa horas válidas (>0)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    // Selector de tipo de sesiones
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<bool>(
                            title: const Text('Una sesión'),
                            value: true,
                            groupValue: isSingleSession,
                            onChanged: (v) => setStateDialog(() => isSingleSession = v ?? true),
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<bool>(
                            title: const Text('Varias sesiones'),
                            value: false,
                            groupValue: isSingleSession,
                            onChanged: (v) => setStateDialog(() => isSingleSession = v ?? false),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (isSingleSession) ...[
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: pickDate,
                              icon: const Icon(Icons.calendar_today),
                              label: Text(singleDate == null
                                  ? 'Seleccionar fecha'
                                  : DateFormat('dd/MM/yyyy').format(singleDate!)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: pickStartTime,
                              icon: const Icon(Icons.access_time),
                              label: Text('Inicio: ${formatTime(singleStart)}'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: pickEndTime,
                              icon: const Icon(Icons.access_time),
                              label: Text('Fin: ${formatTime(singleEnd)}'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: locationController,
                        decoration: const InputDecoration(
                          labelText: 'Ubicación',
                        ),
                        validator: (v) {
                          if (!isSingleSession) return null;
                          return (v == null || v.trim().isEmpty)
                              ? 'Ingresa la ubicación'
                              : null;
                        },
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: maxVolController,
                        decoration: const InputDecoration(
                          labelText: 'Cupo máximo',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (!isSingleSession) return null;
                          final value = int.tryParse(v ?? '');
                          if (value == null || value <= 0) {
                            return 'Ingresa un número válido (>0)';
                          }
                          return null;
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  // Pre-capturar Navigator y ScaffoldMessenger para evitar usar BuildContext tras await
                  final navigator = Navigator.of(context);
                  final messenger = ScaffoldMessenger.of(context);

                  try {
                    String? location;
                    int? maxVol;
                    DateTime? date;
                    DateTime? startDateTime;
                    DateTime? endDateTime;

                    if (isSingleSession) {
                      if (singleDate == null || singleStart == null || singleEnd == null) {
                        messenger.showSnackBar(const SnackBar(content: Text('Completa fecha y horas')));
                        return;
                      }
                      date = singleDate!;
                      startDateTime = DateTime(date.year, date.month, date.day, singleStart!.hour, singleStart!.minute);
                      endDateTime = DateTime(date.year, date.month, date.day, singleEnd!.hour, singleEnd!.minute);
                      location = locationController.text.trim();
                      maxVol = int.tryParse(maxVolController.text.trim());
                    }

                    final id = await EventService.createEvent(
                      title: titleController.text.trim(),
                      description: descriptionController.text.trim(),
                      coordinatorId: widget.user.uid,
                      totalHoursForCertificate: double.parse(hoursController.text.trim()),
                      sessionType: isSingleSession ? SessionType.unica : SessionType.multiple,
                      singleSessionDate: date,
                      singleSessionStartTime: startDateTime,
                      singleSessionEndTime: endDateTime,
                      singleSessionLocation: location,
                      singleSessionMaxVolunteers: maxVol,
                    );
                    navigator.pop();
                    messenger.showSnackBar(
                      SnackBar(content: Text('Programa creado: $id')),
                    );
                    if (!mounted) return;
                    setState(() {});
                  } catch (e) {
                    messenger.showSnackBar(
                      SnackBar(content: Text('Error al crear programa: $e')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Crear'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEventDetails(EventModel event) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Detalles de: ${event.title}'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _showSubEventDetails(SubEventModel subEvent) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Detalles de: ${subEvent.title}'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _handleEventAction(String action, EventModel event) {
    switch (action) {
      case 'edit':
        _showEditEventDialog(event);
        break;
      case 'add_subevent':
        _showCreateSubEventDialog(event.eventId);
        break;
      case 'publish': {
        // Evitar usar BuildContext tras gaps asíncronos
        final messenger = ScaffoldMessenger.of(context);
        EventService.updateEventStatus(event.eventId, EventStatus.publicado).then((_) {
          messenger.showSnackBar(const SnackBar(content: Text('Programa publicado')));
        }).catchError((e) {
          messenger.showSnackBar(SnackBar(content: Text('Error al publicar: $e')));
        });
        break;
      }
      case 'mark_draft':
      {
        // Evitar usar BuildContext tras gaps asíncronos
        final messenger = ScaffoldMessenger.of(context);
        EventService.updateEventStatus(event.eventId, EventStatus.borrador).then((_) {
          messenger.showSnackBar(const SnackBar(content: Text('Programa marcado como borrador')));
        }).catchError((e) {
          messenger.showSnackBar(SnackBar(content: Text('Error al actualizar estado: $e')));
        });
        break;
      }
      case 'scan':
        _showSelectSubEventForScan(event);
        break;
      case 'stats':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Estadísticas próximamente')),
        );
        break;
      case 'delete':
        _showDeleteEventDialog(event);
        break;
    }
  }

  void _handleSubEventAction(String action, SubEventModel subEvent) {
    switch (action) {
      case 'edit':
        _showEditSubEventDialog(subEvent);
        break;
      case 'scan':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => CoordinatorStudentQRScannerScreen(
              eventId: subEvent.baseEventId,
              subEventId: subEvent.subEventId,
              eventTitle: 'Programa',
              subEventTitle: subEvent.title,
            ),
          ),
        );
        break;
      case 'attendance':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AttendanceListScreen(
              coordinatorId: widget.user.uid,
              eventId: subEvent.baseEventId,
              subEventId: subEvent.subEventId,
              eventTitle: 'Programa',
              subEventTitle: subEvent.title,
            ),
          ),
        );
        break;
      case 'delete':
        _showDeleteSubEventDialog(subEvent);
        break;
    }
  }

  void _showDeleteEventDialog(EventModel event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Programa'),
        content: Text(
          '¿Estás seguro de que quieres eliminar "${event.title}"? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              // Pre-capturar el ScaffoldMessenger para evitar usar BuildContext tras la operación async
              final messenger = ScaffoldMessenger.of(context);
              Navigator.of(context).pop();
              EventService.deleteEvent(event.eventId).then((_) {
                messenger.showSnackBar(
                  const SnackBar(content: Text('Programa eliminado')),
                );
                if (!mounted) return;
                setState(() {});
              }).catchError((e) {
                messenger.showSnackBar(
                  SnackBar(content: Text('Error al eliminar: $e')),
                );
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _showCreateSubEventDialog(String eventId) {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final locationController = TextEditingController();
    final maxVolController = TextEditingController(text: '30');
    DateTime? date;
    TimeOfDay? start;
    TimeOfDay? end;

    void pickDate() async {
      final now = DateTime.now();
      final picked = await showDatePicker(
        context: context,
        initialDate: now,
        firstDate: now.subtract(const Duration(days: 0)),
        lastDate: now.add(const Duration(days: 365 * 2)),
      );
      if (picked != null) {
        setState(() => date = picked);
      }
    }

    void pickStartTime() async {
      final picked = await showTimePicker(
        context: context,
        initialTime: const TimeOfDay(hour: 9, minute: 0),
      );
      if (picked != null) {
        setState(() => start = picked);
      }
    }

    void pickEndTime() async {
      final picked = await showTimePicker(
        context: context,
        initialTime: const TimeOfDay(hour: 12, minute: 0),
      );
      if (picked != null) {
        setState(() => end = picked);
      }
    }

    String formatTime(TimeOfDay? t) {
      if (t == null) return 'Seleccionar';
      final dt = DateTime(0, 1, 1, t.hour, t.minute);
      return DateFormat('HH:mm').format(dt);
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Crear Actividad'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Título',
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Ingresa un título'
                      : null,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: pickDate,
                        icon: const Icon(Icons.calendar_today),
                        label: Text(date == null
                            ? 'Seleccionar fecha'
                            : DateFormat('dd/MM/yyyy').format(date!)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: pickStartTime,
                        icon: const Icon(Icons.access_time),
                        label: Text('Inicio: ${formatTime(start)}'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: pickEndTime,
                        icon: const Icon(Icons.access_time),
                        label: Text('Fin: ${formatTime(end)}'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: locationController,
                  decoration: const InputDecoration(
                    labelText: 'Ubicación',
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Ingresa la ubicación'
                      : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: maxVolController,
                  decoration: const InputDecoration(
                    labelText: 'Cupo máximo',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    final value = int.tryParse(v ?? '');
                    if (value == null || value <= 0) {
                      return 'Ingresa un número válido (>0)';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Pre-capturar Navigator y ScaffoldMessenger para evitar usar BuildContext tras await
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);
              if (!formKey.currentState!.validate() || date == null || start == null || end == null) {
                messenger.showSnackBar(
                  const SnackBar(content: Text('Completa fecha y horas')),
                );
                return;
              }
              final startDateTime = DateTime(date!.year, date!.month, date!.day, start!.hour, start!.minute);
              final endDateTime = DateTime(date!.year, date!.month, date!.day, end!.hour, end!.minute);
              try {
                final id = await EventService.createSubEvent(
                  baseEventId: eventId,
                  title: titleController.text.trim(),
                  date: date!,
                  startTime: startDateTime,
                  endTime: endDateTime,
                  location: locationController.text.trim(),
                  maxVolunteers: int.parse(maxVolController.text.trim()),
                );
                navigator.pop();
                messenger.showSnackBar(
                  SnackBar(content: Text('Actividad creada: $id')),
                );
                if (!mounted) return;
                setState(() {});
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(content: Text('Error al crear actividad: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }

  void _showEditEventDialog(EventModel event) {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController(text: event.title);
    final descriptionController = TextEditingController(text: event.description);
    final hoursController = TextEditingController(text: event.totalHoursForCertificate.toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Programa'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Título'),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Ingresa un título'
                      : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Descripción'),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: hoursController,
                  decoration: const InputDecoration(labelText: 'Horas para certificado'),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    final value = double.tryParse(v ?? '');
                    if (value == null || value <= 0) {
                      return 'Ingresa horas válidas (>0)';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              // Pre-capturar Navigator y ScaffoldMessenger para evitar usar BuildContext tras await
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);
              try {
                await EventService.updateEvent(
                  eventId: event.eventId,
                  title: titleController.text.trim(),
                  description: descriptionController.text.trim(),
                  totalHoursForCertificate: double.parse(hoursController.text.trim()),
                );
                navigator.pop();
                messenger.showSnackBar(
                  const SnackBar(content: Text('Programa actualizado')),
                );
                if (!mounted) return;
                setState(() {});
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(content: Text('Error al actualizar: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _showEditSubEventDialog(SubEventModel subEvent) {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController(text: subEvent.title);
    final locationController = TextEditingController(text: subEvent.location);
    final maxVolController = TextEditingController(text: subEvent.maxVolunteers.toString());
    DateTime date = subEvent.date;
    TimeOfDay start = TimeOfDay(hour: subEvent.startTime.hour, minute: subEvent.startTime.minute);
    TimeOfDay end = TimeOfDay(hour: subEvent.endTime.hour, minute: subEvent.endTime.minute);

    void pickDate() async {
      final picked = await showDatePicker(
        context: context,
        initialDate: date,
        firstDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
        lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      );
      if (picked != null) {
        setState(() => date = picked);
      }
    }

    void pickStartTime() async {
      final picked = await showTimePicker(
        context: context,
        initialTime: start,
      );
      if (picked != null) {
        setState(() => start = picked);
      }
    }

    void pickEndTime() async {
      final picked = await showTimePicker(
        context: context,
        initialTime: end,
      );
      if (picked != null) {
        setState(() => end = picked);
      }
    }

    String formatTime(TimeOfDay t) {
      final dt = DateTime(0, 1, 1, t.hour, t.minute);
      return DateFormat('HH:mm').format(dt);
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Actividad'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Título'),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Ingresa un título'
                      : null,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: pickDate,
                        icon: const Icon(Icons.calendar_today),
                        label: Text(DateFormat('dd/MM/yyyy').format(date)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: pickStartTime,
                        icon: const Icon(Icons.access_time),
                        label: Text('Inicio: ${formatTime(start)}'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: pickEndTime,
                        icon: const Icon(Icons.access_time),
                        label: Text('Fin: ${formatTime(end)}'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: locationController,
                  decoration: const InputDecoration(labelText: 'Ubicación'),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Ingresa la ubicación'
                      : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: maxVolController,
                  decoration: const InputDecoration(labelText: 'Cupo máximo'),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    final value = int.tryParse(v ?? '');
                    if (value == null || value <= 0) {
                      return 'Ingresa un número válido (>0)';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final startDateTime = DateTime(date.year, date.month, date.day, start.hour, start.minute);
              final endDateTime = DateTime(date.year, date.month, date.day, end.hour, end.minute);
              // Pre-capturar Navigator y ScaffoldMessenger para evitar usar BuildContext tras await
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);
              try {
                await EventService.updateSubEvent(
                  subEventId: subEvent.subEventId,
                  title: titleController.text.trim(),
                  date: date,
                  startTime: startDateTime,
                  endTime: endDateTime,
                  location: locationController.text.trim(),
                  maxVolunteers: int.parse(maxVolController.text.trim()),
                );
                navigator.pop();
                messenger.showSnackBar(
                  const SnackBar(content: Text('Actividad actualizada')),
                );
                if (!mounted) return;
                setState(() {});
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(content: Text('Error al actualizar: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _showSelectSubEventForScan(EventModel event) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          builder: (_, controller) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const Icon(Icons.qr_code_scanner, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Selecciona una actividad para pasar asistencia',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: StreamBuilder<List<SubEventModel>>(
                    stream: EventService.getSubEventsByEvent(event.eventId),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                                const SizedBox(height: 8),
                                Text(
                                  'Error al cargar actividades: ${snapshot.error}',
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                      }
                      final subEvents = snapshot.data ?? [];
                      if (subEvents.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.event_busy, size: 48, color: Colors.grey),
                                const SizedBox(height: 8),
                                const Text('No hay actividades. Crea una para pasar asistencia.'),
                                const SizedBox(height: 12),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                    _showCreateSubEventDialog(event.eventId);
                                  },
                                  icon: const Icon(Icons.add),
                                  label: const Text('Crear actividad'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      return ListView.separated(
                        controller: controller,
                        itemCount: subEvents.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final s = subEvents[index];
                          return ListTile(
                            leading: const Icon(Icons.event),
                            title: Text(s.title),
                            subtitle: Text('${_formatDate(s.date)} • ${_formatTime(s.startTime)} - ${_formatTime(s.endTime)}'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              Navigator.of(context).pop();
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => CoordinatorStudentQRScannerScreen(
                                    eventId: event.eventId,
                                    subEventId: s.subEventId,
                                    eventTitle: event.title,
                                    subEventTitle: s.title,
                                  ),
                                ),
                              );
                            },
                          );
                        },
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
  }

  void _showDeleteSubEventDialog(SubEventModel subEvent) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Actividad'),
        content: Text(
          '¿Estás seguro de que quieres eliminar "${subEvent.title}"? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              // Pre-capturar el ScaffoldMessenger para evitar usar BuildContext tras la operación async
              final messenger = ScaffoldMessenger.of(context);
              Navigator.of(context).pop();
              EventService.deleteSubEvent(subEvent.subEventId).then((_) {
                messenger.showSnackBar(
                  const SnackBar(content: Text('Actividad eliminada')),
                );
                if (!mounted) return;
                setState(() {});
              }).catchError((e) {
                messenger.showSnackBar(
                  SnackBar(content: Text('Error al eliminar: $e')),
                );
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  Future<int> _getSubEventCount(String eventId) async {
    try {
      return await EventService.getSubEventCountByEvent(eventId);
    } catch (e) {
      return 0;
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
