import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../utils/app_colors.dart';
import '../../utils/feedback_overlay.dart';
import '../../utils/app_dialogs.dart';
import '../../utils/skeleton_loader.dart';
import '../../models/models.dart';
import '../../services/services.dart';
import 'coordinator_student_qr_scanner_screen.dart';
import 'event_registrations_screen.dart';
import 'attendance_list_screen.dart';

// Método para pasar asistencia
enum ScanMethod { qr, list }

class ManageEventsScreen extends StatefulWidget {
  final UserModel user;

  const ManageEventsScreen({super.key, required this.user});

  @override
  State<ManageEventsScreen> createState() => _ManageEventsScreenState();
}

class _ManageEventsScreenState extends State<ManageEventsScreen> {
  static const int _maxEventsPerCoordinator =
      5; // Límite de programas por coordinador

  @override
  void initState() {
    super.initState();
    // Validar rol al abrir pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.user.role != UserRole.coordinador) {
        FeedbackOverlay.showError(
          context,
          'No autorizado. Inicia sesión como coordinador.',
        );
        Navigator.of(context).pop();
      }
    });
  }

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
            onPressed: () => _onAddEventTap(),
            icon: const Icon(Icons.add),
            tooltip: 'Crear Evento',
          ),
        ],
      ),
      body: _buildEventsTab(),
    );
  }

  Future<void> _onAddEventTap() async {
    try {
      final current = await EventService.getEventsByCoordinator(
        widget.user.uid,
      ).first;
      if (current.length >= _maxEventsPerCoordinator) {
        if (!mounted) return;
        FeedbackOverlay.showInfo(
          context,
          'Límite de $_maxEventsPerCoordinator programas alcanzado. Elimina o archiva alguno antes de crear otro.',
        );
        return;
      }
      _showCreateEventDialog();
    } catch (e) {
      if (!mounted) return;
      FeedbackOverlay.showError(context, 'No se pudo verificar el límite de programas');
      // Aún así permitir crear si falla la verificación
      _showCreateEventDialog();
    }
  }

  // Eliminado: pestañas superiores. La UI se simplificó para mostrar solo la lista de programas.

  // Eliminado: botón de pestañas (ya no se usan pestañas en esta pantalla)

  Widget _buildEventsTab() {
    return StreamBuilder<List<EventModel>>(
      stream: EventService.getEventsByCoordinator(widget.user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: 3,
            itemBuilder: (context, index) => const EventCardSkeleton(),
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
                      const PopupMenuItem(
                        value: 'registrations',
                        child: Row(
                          children: [
                            Icon(Icons.people, size: 18),
                            SizedBox(width: 8),
                            Text('Ver inscritos del programa'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: event.status == EventStatus.borrador
                            ? 'publish'
                            : 'mark_draft',
                        child: Row(
                          children: [
                            Icon(
                              event.status == EventStatus.borrador
                                  ? Icons.publish
                                  : Icons.unpublished,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              event.status == EventStatus.borrador
                                  ? 'Publicar'
                                  : 'Marcar como borrador',
                            ),
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
                            Icon(
                              Icons.delete,
                              size: 18,
                              color: AppColors.error,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Eliminar',
                              style: TextStyle(color: AppColors.error),
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
              Row(
                children: [
                  _buildStatusChip(event.status),
                  const SizedBox(width: 8),
                  StreamBuilder<List<SubEventModel>>(
                    stream: EventService.getSubEventsByEvent(event.eventId),
                    builder: (context, snap) {
                      final now = DateTime.now();
                      String text = 'Pendiente';
                      Color color = AppColors.primary;
                      if (snap.hasData && snap.data!.isNotEmpty) {
                        final subs = snap.data!;
                        final hasCompleted = subs.every(
                          (s) => s.endTime.isBefore(now),
                        );
                        final hasStarted = subs.any(
                          (s) =>
                              !s.endTime.isBefore(now) &&
                              s.startTime.isBefore(now),
                        );
                        if (hasCompleted) {
                          text = 'Finalizado';
                          color = Colors.grey;
                        } else if (hasStarted) {
                          text = 'En curso';
                          color = AppColors.accent;
                        }
                      }
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.timelapse, size: 12, color: color),
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
                    },
                  ),
                  const Spacer(),
                  StreamBuilder<List<RegistrationModel>>(
                    stream: EventService.getAllRegistrationsByEvent(
                      event.eventId,
                    ),
                    builder: (context, regSnap) {
                      final count = regSnap.data?.length ?? 0;
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.groups,
                              size: 12,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$count inscritos',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showScanMethodPicker(event),
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Pasar asistencia'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
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
        color = AppColors.primary;
        text = 'Publicado';
        icon = Icons.check_circle;
        break;
      case EventStatus.completado:
        color = AppColors.success;
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

  // Eliminado: chip de estado de sub-actividad (pantalla sin gestión directa de sub-actividades)

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

  // Eliminado: estado vacío de sub-actividades (no hay pestaña de actividades en esta pantalla)

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

    bool isSubmitting = false;
    StateSetter? setStateDialogRef;
    AppDialogs.modal(
      context,
      title: 'Crear Programa',
      icon: Icons.event,
      content: StatefulBuilder(
        builder: (context, setStateDialog) {
          setStateDialogRef = setStateDialog;
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

          return Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Información básica
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Información básica',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Título',
                      hintText: 'Nombre del programa',
                      prefixIcon: Icon(Icons.event),
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
                      prefixIcon: Icon(Icons.description),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: hoursController,
                    decoration: const InputDecoration(
                      labelText: 'Horas para certificado',
                      hintText: 'Ej. 20',
                      prefixIcon: Icon(Icons.schedule),
                      helperText:
                          'Horas totales del programa que contarán para el certificado',
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
                  const SizedBox(height: 16),
                  // Tipo de sesiones
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Tipo de sesiones',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Una sesión'),
                        selected: isSingleSession,
                        onSelected: (_) =>
                            setStateDialog(() => isSingleSession = true),
                      ),
                      ChoiceChip(
                        label: const Text('Varias sesiones'),
                        selected: !isSingleSession,
                        onSelected: (_) =>
                            setStateDialog(() => isSingleSession = false),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (isSingleSession) ...[
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: pickDate,
                                    icon: const Icon(Icons.calendar_today),
                                    label: Text(
                                      singleDate == null
                                          ? 'Seleccionar fecha'
                                          : DateFormat(
                                              'dd/MM/yyyy',
                                            ).format(singleDate!),
                                    ),
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
                                    label: Text(
                                      'Inicio: ${formatTime(singleStart)}',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: pickEndTime,
                                    icon: const Icon(Icons.access_time),
                                    label: Text(
                                      'Fin: ${formatTime(singleEnd)}',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: locationController,
                              decoration: const InputDecoration(
                                labelText: 'Ubicación',
                                hintText: 'Lugar físico o sala virtual',
                                prefixIcon: Icon(Icons.place),
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
                                labelText: 'Cupo máximo (opcional)',
                                hintText: 'Dejar vacío para sin límite',
                                prefixIcon: Icon(Icons.people_alt),
                                helperText: 'Si no especificas, no habrá límite de inscritos',
                              ),
                              keyboardType: TextInputType.number,
                              validator: (v) {
                                if (!isSingleSession) return null;
                                if (v == null || v.trim().isEmpty) return null; // Opcional
                                final value = int.tryParse(v);
                                if (value == null || value <= 0) {
                                  return 'Ingresa un número válido mayor a 0';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
          // Eliminado punto y coma sobrante que cerraba indebidamente antes del builder
        },
      ),
      actions: [
        AppDialogs.cancelAction(
          onPressed: () => Navigator.of(context).pop(),
        ),
        StatefulBuilder(
          builder: (context, setBtn) {
            setStateDialogRef = setStateDialogRef ?? setBtn;
            return ElevatedButton(
              onPressed: isSubmitting ? null : () async {
                if (!formKey.currentState!.validate()) return;

            final ctx = context;
            final navigator = Navigator.of(ctx);

            try {
              setStateDialogRef?.call(() => isSubmitting = true);
              String? location;
              int? maxVol;
              DateTime? date;
              DateTime? startDateTime;
              DateTime? endDateTime;

              if (isSingleSession) {
                if (singleDate == null ||
                    singleStart == null ||
                    singleEnd == null) {
                  FeedbackOverlay.showInfo(ctx, 'Completa fecha y horas');
                  return;
                }
                date = singleDate!;
                startDateTime = DateTime(
                  date.year,
                  date.month,
                  date.day,
                  singleStart!.hour,
                  singleStart!.minute,
                );
                endDateTime = DateTime(
                  date.year,
                  date.month,
                  date.day,
                  singleEnd!.hour,
                  singleEnd!.minute,
                );
                location = locationController.text.trim();
                // Si no se especifica cupo, usar un número grande (sin límite efectivo)
                final maxVolText = maxVolController.text.trim();
                maxVol = maxVolText.isEmpty ? 9999 : int.tryParse(maxVolText);
              }

              final programTitle = titleController.text.trim();
              await EventService.createEvent(
                title: programTitle,
                description: descriptionController.text.trim(),
                coordinatorId: widget.user.uid,
                totalHoursForCertificate: double.parse(
                  hoursController.text.trim(),
                ),
                sessionType: isSingleSession
                    ? SessionType.unica
                    : SessionType.multiple,
                singleSessionDate: date,
                singleSessionStartTime: startDateTime,
                singleSessionEndTime: endDateTime,
                singleSessionLocation: location,
                singleSessionMaxVolunteers: maxVol,
              );
              if (!ctx.mounted) return;
              navigator.pop();
              FeedbackOverlay.showSuccess(ctx, 'Programa "$programTitle" creado exitosamente');
              setState(() {});
            } catch (e) {
              if (!ctx.mounted) return;
              FeedbackOverlay.showError(ctx, 'No se pudo crear el programa. Verifica los datos e intenta nuevamente');
            } finally {
              setStateDialogRef?.call(() => isSubmitting = false);
            }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Crear'),
            );
          },
        ),
      ],
    );
  }

  void _showEventDetails(EventModel event) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.8,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          builder: (context, controller) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  
                  Expanded(
                    child: SingleChildScrollView(
                      controller: controller,
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Encabezado con título y estado
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      event.title,
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                        height: 1.2,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    _buildStatusChip(event.status),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () => Navigator.of(context).pop(),
                                icon: const Icon(Icons.close),
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.grey[100],
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Descripción
                          if (event.description.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[200]!),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.description, 
                                    size: 20, 
                                    color: Colors.grey[600]
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      event.description,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[700],
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          
                          // Estadísticas en cards
                          StreamBuilder<List<RegistrationModel>>(
                            stream: EventService.getAllRegistrationsByEvent(event.eventId),
                            builder: (context, regSnapshot) {
                              final inscritos = regSnapshot.data?.length ?? 0;
                              
                              return FutureBuilder<int>(
                                future: _getSubEventCount(event.eventId),
                                builder: (context, actSnapshot) {
                                  final actividades = actSnapshot.data ?? 0;
                                  
                                  return Row(
                                    children: [
                                      Expanded(
                                        child: _buildStatCard(
                                          icon: Icons.schedule,
                                          value: '${event.totalHoursForCertificate.toInt()}h',
                                          label: 'Para certificado',
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _buildStatCard(
                                          icon: Icons.event,
                                          value: '$actividades',
                                          label: 'Actividades',
                                          color: AppColors.accent,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _buildStatCard(
                                          icon: Icons.people,
                                          value: '$inscritos',
                                          label: 'Inscritos',
                                          color: AppColors.success,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Título de actividades
                          Row(
                            children: [
                              const Icon(
                                Icons.event_note,
                                size: 22,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Actividades del Programa',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 12),
                          
                          // Lista de actividades
                          StreamBuilder<List<SubEventModel>>(
                            stream: EventService.getSubEventsByEvent(event.eventId),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(32.0),
                                    child: CircularProgressIndicator(
                                      color: AppColors.primary,
                                    ),
                                  ),
                                );
                              }
                              
                              final subEvents = snapshot.data ?? [];
                              
                              if (subEvents.isEmpty) {
                                return Container(
                                  padding: const EdgeInsets.all(32),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.grey[200]!,
                                      style: BorderStyle.solid,
                                      width: 2,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.event_busy,
                                        size: 56,
                                        color: Colors.grey[400],
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'No hay actividades creadas',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Crea tu primera actividad para este programa',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[600],
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 16),
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                          _showCreateSubEventDialog(event.eventId);
                                        },
                                        icon: const Icon(Icons.add_circle),
                                        label: const Text('Crear actividad'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primary,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 24,
                                            vertical: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }
                              
                              return Column(
                                children: subEvents.map((s) {
                                  final now = DateTime.now();
                                  final isPast = s.endTime.isBefore(now);
                                  final isToday = s.date.day == now.day &&
                                      s.date.month == now.month &&
                                      s.date.year == now.year;
                                  
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    decoration: BoxDecoration(
                                      color: isPast 
                                          ? Colors.grey[50]
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isToday
                                            ? AppColors.accent
                                            : Colors.grey[300]!,
                                        width: isToday ? 2 : 1,
                                      ),
                                      boxShadow: [
                                        if (!isPast)
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.04),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                      ],
                                    ),
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      leading: Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: isPast
                                              ? Colors.grey[200]
                                              : AppColors.primary.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Icon(
                                          isPast ? Icons.check_circle : Icons.event,
                                          color: isPast
                                              ? Colors.grey[500]
                                              : AppColors.primary,
                                          size: 24,
                                        ),
                                      ),
                                      title: Text(
                                        s.title,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: isPast
                                              ? Colors.grey[600]
                                              : AppColors.textPrimary,
                                        ),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.calendar_today,
                                                size: 12,
                                                color: Colors.grey[600],
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                _formatDate(s.date),
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Icon(
                                                Icons.access_time,
                                                size: 12,
                                                color: Colors.grey[600],
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                '${_formatTime(s.startTime)} - ${_formatTime(s.endTime)}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.location_on,
                                                size: 12,
                                                color: Colors.grey[600],
                                              ),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  s.location,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[600],
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      trailing: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isPast
                                              ? Colors.grey[200]
                                              : _getCapacityColor(
                                                  s.registeredCount,
                                                  s.maxVolunteers,
                                                ).withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          '${s.registeredCount}/${s.maxVolunteers}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: isPast
                                                ? Colors.grey[600]
                                                : _getCapacityColor(
                                                    s.registeredCount,
                                                    s.maxVolunteers,
                                                  ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              );
                            },
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Acciones principales
                          const Text(
                            'Acciones',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          
                          const SizedBox(height: 12),
                          
                          // Botones de acción en grid
                          _buildActionButton(
                            icon: Icons.qr_code_scanner,
                            label: 'Pasar Asistencia',
                            color: AppColors.primary,
                            onTap: () {
                              Navigator.of(context).pop();
                              _showScanMethodPicker(event);
                            },
                          ),
                          
                          const SizedBox(height: 8),
                          
                          Row(
                            children: [
                              Expanded(
                                child: _buildActionButton(
                                  icon: Icons.people,
                                  label: 'Ver Inscritos',
                                  color: AppColors.success,
                                  onTap: () {
                                    Navigator.of(context).pop();
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => EventRegistrationsScreen(
                                          eventId: event.eventId,
                                          eventTitle: event.title,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildActionButton(
                                  icon: Icons.add_circle,
                                  label: 'Nueva Actividad',
                                  color: AppColors.accent,
                                  onTap: () {
                                    Navigator.of(context).pop();
                                    _showCreateSubEventDialog(event.eventId);
                                  },
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 12),
                          
                          // Botones secundarios
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                    _showEditEventDialog(event);
                                  },
                                  icon: const Icon(Icons.edit, size: 18),
                                  label: const Text('Editar'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.primary,
                                    side: const BorderSide(color: AppColors.primary),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () async {
                                    final ctx = context;
                                    try {
                                      await EventService.updateEventStatus(
                                        event.eventId,
                                        event.status == EventStatus.borrador
                                            ? EventStatus.publicado
                                            : EventStatus.borrador,
                                      );
                                      if (!ctx.mounted) return;
                                      Navigator.of(ctx).pop();
                                      FeedbackOverlay.showSuccess(
                                        ctx,
                                        event.status == EventStatus.borrador
                                            ? 'Programa publicado'
                                            : 'Programa marcado como borrador',
                                      );
                                    } catch (e) {
                                      if (!ctx.mounted) return;
                              FeedbackOverlay.showError(
                                ctx,
                                'No se pudo actualizar el estado',
                              );
                                    }
                                  },
                                  icon: Icon(
                                    event.status == EventStatus.borrador
                                        ? Icons.publish
                                        : Icons.unpublished,
                                    size: 18,
                                  ),
                                  label: Text(
                                    event.status == EventStatus.borrador
                                        ? 'Publicar'
                                        : 'Despublicar',
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.primary,
                                    side: const BorderSide(color: AppColors.primary),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 8),
                          
                          // Botón eliminar
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.of(context).pop();
                                _showDeleteEventDialog(event);
                              },
                              icon: const Icon(Icons.delete, size: 18),
                              label: const Text('Eliminar Programa'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.error,
                                side: const BorderSide(color: AppColors.error),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
  
  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
  
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 22),
              const SizedBox(width: 10),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Color _getCapacityColor(int registered, int max) {
    final percentage = registered / max;
    if (percentage >= 0.9) return AppColors.error;
    if (percentage >= 0.7) return AppColors.accent;
    return AppColors.success;
  }

  // Eliminado: detalles de sub-actividad (no se usan en esta pantalla)

  void _handleEventAction(String action, EventModel event) async {
    switch (action) {
      case 'edit':
        _showEditEventDialog(event);
        break;
      case 'registrations':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => EventRegistrationsScreen(
              eventId: event.eventId,
              eventTitle: event.title,
            ),
          ),
        );
        break;
      case 'add_subevent':
        _showCreateSubEventDialog(event.eventId);
        break;
      case 'publish':
        final ctx = context;
        try {
          await EventService.updateEventStatus(
            event.eventId,
            EventStatus.publicado,
          );
          if (!ctx.mounted) return;
          FeedbackOverlay.showSuccess(ctx, 'Programa publicado');
        } catch (e) {
          if (!ctx.mounted) return;
          FeedbackOverlay.showError(ctx, 'No se pudo publicar el programa');
        }
        break;
      case 'mark_draft':
        final ctx = context;
        try {
          await EventService.updateEventStatus(
            event.eventId,
            EventStatus.borrador,
          );
          if (!ctx.mounted) return;
          FeedbackOverlay.showInfo(ctx, 'Programa marcado como borrador');
        } catch (e) {
          if (!ctx.mounted) return;
          FeedbackOverlay.showError(ctx, 'No se pudo actualizar el estado del programa');
        }
        break;
      case 'scan':
        _showScanMethodPicker(event);
        break;
      case 'stats':
        FeedbackOverlay.showInfo(context, 'Estadísticas próximamente');
        break;
      case 'delete':
        _showDeleteEventDialog(event);
        break;
    }
  }

  // Eliminado: manejador de acciones de sub-actividad (ya no se activan desde esta pantalla)

  void _showDeleteEventDialog(EventModel event) {
    AppDialogs.modal(
      context,
      title: 'Eliminar Programa',
      icon: Icons.delete_outline,
      iconColor: AppColors.error,
      content: Text(
        '¿Estás seguro de que quieres eliminar "${event.title}"? Esta acción no se puede deshacer.',
      ),
      actions: [
        AppDialogs.cancelAction(onPressed: () => Navigator.of(context).pop()),
        AppDialogs.dangerAction(
          label: 'Eliminar',
          onPressed: () async {
            Navigator.of(context).pop();
            try {
              await EventService.deleteEvent(event.eventId);
              if (!mounted) return;
              FeedbackOverlay.showSuccess(context, 'Programa eliminado');
              setState(() {});
            } catch (e) {
              if (!mounted) return;
              FeedbackOverlay.showError(context, 'No se pudo eliminar el programa');
            }
          },
        ),
      ],
    );
  }

  void _showCreateSubEventDialog(String eventId) {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final locationController = TextEditingController();
    final maxVolController = TextEditingController(); // Vacío por defecto (sin límite)
    DateTime? date;
    TimeOfDay? start;
    TimeOfDay? end;
    bool isSubmitting = false;
    StateSetter? setStateDialogRef;
    AppDialogs.modal(
      context,
      title: 'Crear Actividad',
      icon: Icons.event,
      content: StatefulBuilder(
        builder: (context, setStateDialog) {
          setStateDialogRef = setStateDialog;
          void pickDate() async {
            final now = DateTime.now();
            final picked = await showDatePicker(
              context: context,
              initialDate: now,
              firstDate: now.subtract(const Duration(days: 0)),
              lastDate: now.add(const Duration(days: 365 * 2)),
            );
            if (picked != null) {
              setStateDialog(() => date = picked);
            }
          }

          void pickStartTime() async {
            final picked = await showTimePicker(
              context: context,
              initialTime: const TimeOfDay(hour: 9, minute: 0),
            );
            if (picked != null) {
              setStateDialog(() => start = picked);
            }
          }

          void pickEndTime() async {
            final picked = await showTimePicker(
              context: context,
              initialTime: const TimeOfDay(hour: 12, minute: 0),
            );
            if (picked != null) {
              setStateDialog(() => end = picked);
            }
          }

          String formatTime(TimeOfDay? t) {
            if (t == null) return 'Seleccionar';
            final dt = DateTime(0, 1, 1, t.hour, t.minute);
            return DateFormat('HH:mm').format(dt);
          }

          return Form(
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
                          label: Text(
                            date == null
                                ? 'Seleccionar fecha'
                                : DateFormat('dd/MM/yyyy').format(date!),
                          ),
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
                    decoration: const InputDecoration(
                      labelText: 'Cupo máximo (opcional)',
                      hintText: 'Dejar vacío para sin límite',
                      helperText: 'Si no especificas, no habrá límite de inscritos',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return null; // Opcional
                      final value = int.tryParse(v);
                      if (value == null || value <= 0) {
                        return 'Ingresa un número válido mayor a 0';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
      actions: [
        AppDialogs.cancelAction(
          onPressed: () => Navigator.of(context).pop(),
        ),
        StatefulBuilder(
          builder: (context, setBtn) {
            setStateDialogRef = setStateDialogRef ?? setBtn;
            return ElevatedButton(
              onPressed: isSubmitting ? null : () async {
                final ctx = context;
                final navigator = Navigator.of(ctx);
                if (!formKey.currentState!.validate() ||
                    date == null ||
                    start == null ||
                    end == null) {
                  FeedbackOverlay.showInfo(ctx, 'Completa fecha y horas');
                  return;
                }
                final startDateTime = DateTime(
                  date!.year,
                  date!.month,
                  date!.day,
                  start!.hour,
                  start!.minute,
                );
                final endDateTime = DateTime(
                  date!.year,
                  date!.month,
                  date!.day,
                  end!.hour,
                  end!.minute,
                );
                try {
                  setStateDialogRef?.call(() => isSubmitting = true);
                  final activityTitle = titleController.text.trim();
                  // Si no se especifica cupo, usar un número grande (sin límite efectivo)
                  final maxVolText = maxVolController.text.trim();
                  final maxVolunteers = maxVolText.isEmpty ? 9999 : int.parse(maxVolText);
                  
                  await EventService.createSubEvent(
                    baseEventId: eventId,
                    title: activityTitle,
                    date: date!,
                    startTime: startDateTime,
                    endTime: endDateTime,
                    location: locationController.text.trim(),
                    maxVolunteers: maxVolunteers,
                  );
                  if (!ctx.mounted) return;
                  navigator.pop();
                  FeedbackOverlay.showSuccess(ctx, 'Actividad "$activityTitle" creada exitosamente');
                  setState(() {});
                } catch (e) {
                  if (!ctx.mounted) return;
                  FeedbackOverlay.showError(ctx, 'No se pudo crear la actividad. Verifica los datos');
                } finally {
                  setStateDialogRef?.call(() => isSubmitting = false);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Crear'),
            );
          },
        ),
      ],
    );
  }

  void _showEditEventDialog(EventModel event) {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController(text: event.title);
    final descriptionController = TextEditingController(
      text: event.description,
    );
    final hoursController = TextEditingController(
      text: event.totalHoursForCertificate.toStringAsFixed(0),
    );
    bool isSubmitting = false;
    StateSetter? setStateDialogRef;
    
    AppDialogs.modal(
      context,
      title: 'Editar Programa',
      icon: Icons.edit,
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
                decoration: const InputDecoration(
                  labelText: 'Horas para certificado',
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
            ],
          ),
        ),
      ),
      actions: [
        AppDialogs.cancelAction(
          onPressed: () => Navigator.of(context).pop(),
        ),
        StatefulBuilder(
          builder: (context, setBtn) {
            setStateDialogRef = setBtn;
            return ElevatedButton(
              onPressed: isSubmitting ? null : () async {
                if (!formKey.currentState!.validate()) return;
                final ctx = context;
                final navigator = Navigator.of(ctx);
                try {
                  setStateDialogRef?.call(() => isSubmitting = true);
                  final programTitle = titleController.text.trim();
                  await EventService.updateEvent(
                    eventId: event.eventId,
                    title: programTitle,
                    description: descriptionController.text.trim(),
                    totalHoursForCertificate: double.parse(
                      hoursController.text.trim(),
                    ),
                  );
                  if (!ctx.mounted) return;
                  navigator.pop();
                  FeedbackOverlay.showSuccess(ctx, 'Programa "$programTitle" actualizado exitosamente');
                  setState(() {});
                } catch (e) {
                  if (!ctx.mounted) return;
                  FeedbackOverlay.showError(ctx, 'No se pudo actualizar el programa');
                } finally {
                  setStateDialogRef?.call(() => isSubmitting = false);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Guardar'),
            );
          },
        ),
      ],
    );
  }

  void _showScanMethodPicker(EventModel event) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.how_to_vote,
                  size: 36,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 8),
                const Text(
                  '¿Cómo deseas pasar asistencia?',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _ScanMethodCard(
                        icon: Icons.qr_code_scanner,
                        title: 'Escanear QR',
                        subtitle: 'Usa la cámara para escanear códigos',
                        onTap: () {
                          Navigator.of(context).pop();
                          _showSelectSubEventForScanMethod(
                            event,
                            ScanMethod.qr,
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ScanMethodCard(
                        icon: Icons.list_alt,
                        title: 'Por lista',
                        subtitle: 'Marca manualmente a los inscritos',
                        onTap: () {
                          Navigator.of(context).pop();
                          _showSelectSubEventForScanMethod(
                            event,
                            ScanMethod.list,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSelectSubEventForScanMethod(EventModel event, ScanMethod method) {
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
                      const Icon(
                        Icons.qr_code_scanner,
                        color: AppColors.primary,
                      ),
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
                                const Icon(
                                  Icons.error_outline,
                                  size: 48,
                                  color: AppColors.error,
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'No se pudieron cargar las actividades',
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        );
                      }
                      final subEvents = snapshot.data ?? [];
                      if (subEvents.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.event_busy,
                                  size: 48,
                                  color: Colors.grey,
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'No hay actividades. Crea una para pasar asistencia.',
                                ),
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
                            subtitle: Text(
                              '${_formatDate(s.date)} • ${_formatTime(s.startTime)} - ${_formatTime(s.endTime)}',
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              Navigator.of(context).pop();
                              if (method == ScanMethod.qr) {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        CoordinatorStudentQRScannerScreen(
                                          eventId: event.eventId,
                                          subEventId: s.subEventId,
                                          eventTitle: event.title,
                                          subEventTitle: s.title,
                                        ),
                                  ),
                                );
                              } else {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => AttendanceListScreen(
                                      coordinatorId: widget.user.uid,
                                      eventId: event.eventId,
                                      subEventId: s.subEventId,
                                      eventTitle: event.title,
                                      subEventTitle: s.title,
                                    ),
                                  ),
                                );
                              }
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

// Tarjeta reutilizable para seleccionar el método de asistencia
class _ScanMethodCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ScanMethodCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 32, color: AppColors.primary),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
