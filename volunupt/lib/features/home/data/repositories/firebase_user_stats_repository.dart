import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/user_stats_entity.dart';
import '../../domain/repositories/user_stats_repository.dart';

class FirebaseUserStatsRepository implements UserStatsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<UserStatsEntity> getUserStats(String userId) async {
    try {
      final inscriptionsSnapshot = await _firestore
          .collection('inscriptions')
          .where('userId', isEqualTo: userId)
          .get();

      final certificatesSnapshot = await _firestore
          .collection('certificates')
          .where('userId', isEqualTo: userId)
          .get();

      int completedEvents = 0;
      int totalHours = 0;
      int activeInscriptions = 0;
      int attendedEvents = 0;

      for (final doc in inscriptionsSnapshot.docs) {
        final data = doc.data();
        final status = data['status'] as String?;
        
        if (status == 'attended') {
          attendedEvents++;
          completedEvents++;
          
          final eventDoc = await _firestore
              .collection('events')
              .doc(data['eventId'])
              .get();
          
          if (eventDoc.exists) {
            final eventData = eventDoc.data()!;
            totalHours += (eventData['volunteerHours'] as int? ?? 0);
          }
        } else if (status == 'registered') {
          activeInscriptions++;
        }
      }

      return UserStatsEntity(
        completedEvents: completedEvents,
        totalHours: totalHours,
        certificates: certificatesSnapshot.docs.length,
        activeInscriptions: activeInscriptions,
        attendedEvents: attendedEvents,
      );
    } catch (e) {
      throw Exception('Error al obtener estadísticas del usuario: $e');
    }
  }

  @override
  Stream<UserStatsEntity> getUserStatsStream(String userId) {
    return _firestore
        .collection('inscriptions')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .asyncMap((snapshot) async {
      try {
        final certificatesSnapshot = await _firestore
            .collection('certificates')
            .where('userId', isEqualTo: userId)
            .get();

        int completedEvents = 0;
        int totalHours = 0;
        int activeInscriptions = 0;
        int attendedEvents = 0;

        for (final doc in snapshot.docs) {
          final data = doc.data();
          final status = data['status'] as String?;
          
          if (status == 'attended') {
            attendedEvents++;
            completedEvents++;
            
            final eventDoc = await _firestore
                .collection('events')
                .doc(data['eventId'])
                .get();
            
            if (eventDoc.exists) {
              final eventData = eventDoc.data()!;
              totalHours += (eventData['volunteerHours'] as int? ?? 0);
            }
          } else if (status == 'registered') {
            activeInscriptions++;
          }
        }

        return UserStatsEntity(
          completedEvents: completedEvents,
          totalHours: totalHours,
          certificates: certificatesSnapshot.docs.length,
          activeInscriptions: activeInscriptions,
          attendedEvents: attendedEvents,
        );
      } catch (e) {
        return const UserStatsEntity(
          completedEvents: 0,
          totalHours: 0,
          certificates: 0,
          activeInscriptions: 0,
          attendedEvents: 0,
        );
      }
    });
  }
}