import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../models/models.dart';
import '../../services/services.dart';
import '../../utils/feedback_overlay.dart';

class AttendanceListScreen extends StatefulWidget {
  final String coordinatorId;
  final String eventId;
  final String subEventId;
  final String eventTitle;
  final String subEventTitle;

  const AttendanceListScreen({
    super.key,
    required this.coordinatorId,
    required this.eventId,
    required this.subEventId,
    required this.eventTitle,
    required this.subEventTitle,
  });

  @override
  State<AttendanceListScreen> createState() => _AttendanceListScreenState();
}

class _AttendanceListScreenState extends State<AttendanceListScreen> {
  // Para evitar envíos duplicados por múltiples clics
  final Set<String> _checkingIds = {};
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Asistencia: ${widget.subEventTitle}',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<List<AttendanceRecordModel>>(
        stream: AttendanceService.getSubEventAttendance(widget.subEventId),
        builder: (context, attendanceSnapshot) {
          final attendanceRecords = attendanceSnapshot.data ?? [];

          return StreamBuilder<List<RegistrationModel>>(
            stream: EventService.getSubEventRegistrations(widget.subEventId),
            builder: (context, subSnapshot) {
              if (subSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: AppColors.primary));
              }

              if (subSnapshot.hasError) {
                return _buildEmptyState('Error al cargar inscripciones de la actividad');
              }

              final subRegs = subSnapshot.data ?? [];

              return FutureBuilder<SubEventModel?>(
                future: EventService.getSubEventById(widget.subEventId),
                builder: (context, subEventSnap) {
                  final now = DateTime.now();
                  bool canMarkNow = true;
                  final s = subEventSnap.data;
                  if (s != null) {
                    final open = s.startTime.subtract(const Duration(hours: 1));
                    final close = s.endTime.add(const Duration(hours: 2));
                    canMarkNow = now.isAfter(open) && now.isBefore(close);
                  }

                  return StreamBuilder<List<RegistrationModel>>(
                    stream: EventService.getEventRegistrations(widget.eventId),
                    builder: (context, eventSnapshot) {
                      if (eventSnapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                      }

                      if (eventSnapshot.hasError) {
                        final merged = subRegs;
                        if (merged.isEmpty) {
                          return _buildEmptyState('No hay estudiantes inscritos en esta actividad ni en el programa');
                        }
                        return _buildRegistrationsList(merged, canMarkNow, attendanceRecords);
                      }

                      final eventRegs = eventSnapshot.data ?? [];
                      final byUser = <String, RegistrationModel>{};
                      for (final r in [...eventRegs, ...subRegs]) {
                        byUser[r.userId] = r;
                      }
                      final merged = byUser.values.toList()
                        ..sort((a, b) => a.registeredAt.compareTo(b.registeredAt));

                      if (merged.isEmpty) {
                        return _buildEmptyState('No hay estudiantes inscritos en esta actividad ni en el programa');
                      }
                      return _buildRegistrationsList(merged, canMarkNow, attendanceRecords);
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildRegistrationsList(List<RegistrationModel> registrations, bool canMarkNow, List<AttendanceRecordModel> attendanceRecords) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: registrations.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final reg = registrations[index];
        final hasAttendance = attendanceRecords.any((a) => a.userId == reg.userId);
        return _buildRegistrationTile(reg, canMarkNow, hasAttendance);
      },
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.people_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),
            const Text(
              'Asegúrate de que esta actividad tenga inscritos. Si no hay, invita estudiantes desde el programa.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegistrationTile(RegistrationModel registration, bool canMarkNow, bool hasAttendance) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const CircleAvatar(child: Icon(Icons.person)),
            const SizedBox(width: 12),
            Expanded(
              child: FutureBuilder<UserModel?>(
                future: UserService.getUserProfile(registration.userId),
                builder: (context, snap) {
                  final user = snap.data;
                  final title = user?.displayName ?? 'Estudiante';
                  final subtitle = user?.email ?? '';
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      if (subtitle.isNotEmpty)
                        Text(
                          subtitle,
                          style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                        ),
                      const SizedBox(height: 6),
                      _originChip(registration.subEventId.isEmpty),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 170,
              child: FutureBuilder<UserModel?>(
                future: UserService.getUserProfile(registration.userId),
                builder: (ctx, userSnap) {
                  final studentName = userSnap.data?.displayName ?? 'Estudiante';
                  
                  if (hasAttendance) {
                    return OutlinedButton.icon(
                      onPressed: null,
                      icon: const Icon(Icons.check_circle, color: AppColors.success),
                      label: const Text('Asistió', style: TextStyle(color: AppColors.success)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.success),
                        disabledForegroundColor: AppColors.success,
                      ),
                    );
                  }

                  return ElevatedButton.icon(
                onPressed: (!_checkingIds.contains(registration.userId) && canMarkNow)
                        ? () => _manualCheckIn(registration.userId, studentName)
                    : null,
                icon: const Icon(Icons.check_circle_outline),
                label: Text(canMarkNow ? 'Marcar asistencia' : 'Fuera de horario'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(170, 44),
                  textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _originChip(bool isProgramRegistration) {
    final label = isProgramRegistration ? 'Inscrito al programa' : 'Inscrito a la actividad';
    final color = isProgramRegistration ? AppColors.primary : AppColors.success;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isProgramRegistration ? Icons.school : Icons.event, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: color),
          ),
        ],
      ),
    );
  }

  Future<void> _manualCheckIn(String studentId, String studentName) async {
    try {
      setState(() => _checkingIds.add(studentId));
      await AttendanceService.coordinatorManualCheckInStudent(
        coordinatorId: widget.coordinatorId,
        eventId: widget.eventId,
        subEventId: widget.subEventId,
        studentId: studentId,
      );
      if (!mounted) return;
      await FeedbackOverlay.showSuccess(context, 'Asistencia de $studentName registrada exitosamente');
    } catch (e) {
      if (!mounted) return;
      await FeedbackOverlay.showError(context, 'No se pudo registrar la asistencia de $studentName');
    } finally {
      if (mounted) setState(() => _checkingIds.remove(studentId));
    }
  }
}