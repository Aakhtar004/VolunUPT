import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../models/models.dart';
import '../../services/services.dart';

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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Asistencia: ${widget.subEventTitle}',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<List<RegistrationModel>>(
        // Mostrar inscritos al programa (evento base) para poder pasar asistencia
        // a cualquier estudiante inscrito, no solo a los de la actividad.
        stream: EventService.getEventRegistrations(widget.eventId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          if (snapshot.hasError) {
            return _buildEmptyState('Error al cargar inscripciones del programa');
          }

          final registrations = snapshot.data ?? [];
          if (registrations.isEmpty) {
            return _buildEmptyState('No hay estudiantes inscritos a este programa');
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: registrations.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final reg = registrations[index];
              return _buildRegistrationTile(reg);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.people_outline, size: 56, color: Colors.grey),
          const SizedBox(height: 8),
          Text(message, style: const TextStyle(color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildRegistrationTile(RegistrationModel registration) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: FutureBuilder<UserModel?>(
                future: UserService.getUserProfile(registration.userId),
                builder: (context, snap) {
                  final user = snap.data;
                  final title = user?.displayName ?? 'Estudiante';
                  final subtitle = user?.email ?? 'ID: ${registration.userId}';
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
                      Text(
                        subtitle,
                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () => _manualCheckIn(registration.userId),
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Marcar asistencia'),
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

  Future<void> _manualCheckIn(String studentId) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final recordId = await AttendanceService.coordinatorManualCheckInStudent(
        coordinatorId: widget.coordinatorId,
        eventId: widget.eventId,
        subEventId: widget.subEventId,
        studentId: studentId,
      );
      messenger.showSnackBar(
        SnackBar(content: Text('Asistencia registrada: $recordId')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }
}