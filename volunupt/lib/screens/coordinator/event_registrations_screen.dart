import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../models/models.dart';
import '../../services/services.dart';

class EventRegistrationsScreen extends StatelessWidget {
  final String eventId;
  final String eventTitle;

  const EventRegistrationsScreen({
    super.key,
    required this.eventId,
    required this.eventTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Inscritos: $eventTitle',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<List<RegistrationModel>>(
        stream: EventService.getAllRegistrationsByEvent(eventId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (snapshot.hasError) {
            return _buildEmptyState(message: 'Error al cargar inscritos');
          }

          final registrations = snapshot.data ?? [];
          if (registrations.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: registrations.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final reg = registrations[index];
              return _RegistrationTile(registration: reg);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState({String message = 'Aún no hay inscritos para este programa'}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.people_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              'Comparte el programa para que los estudiantes se inscriban.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class _RegistrationTile extends StatelessWidget {
  final RegistrationModel registration;
  const _RegistrationTile({required this.registration});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CircleAvatar(radius: 20, child: Icon(Icons.person)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FutureBuilder<UserModel?>(
                    future: UserService.getUserProfile(registration.userId),
                    builder: (context, userSnapshot) {
                      final name = userSnapshot.data?.displayName ?? 'Usuario';
                      final email = userSnapshot.data?.email ?? '';
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (email.isNotEmpty)
                            Text(
                              email,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  FutureBuilder<SubEventModel?>(
                    future: registration.subEventId.isEmpty
                        ? Future.value(null)
                        : EventService.getSubEventById(registration.subEventId),
                    builder: (context, subEventSnapshot) {
                      final placeLabel = subEventSnapshot.data?.location;
                      final title = registration.subEventId.isEmpty
                          ? 'Programa'
                          : (subEventSnapshot.data?.title ?? 'Actividad');
                      return Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          _chip(title, Icons.event),
                          if (placeLabel != null && placeLabel.isNotEmpty)
                            _chip(placeLabel, Icons.place),
                          _chip(
                            _formatDate(registration.registeredAt),
                            Icons.calendar_month,
                          ),
                        ],
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

  Widget _chip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
