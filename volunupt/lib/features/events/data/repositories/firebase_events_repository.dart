import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/event_entity.dart';
import '../../domain/entities/inscription_entity.dart';
import '../../domain/repositories/events_repository.dart';

class FirebaseEventsRepository implements EventsRepository {
  final FirebaseFirestore _firestore;

  FirebaseEventsRepository(this._firestore);

  @override
  Future<List<EventEntity>> getAllEvents() async {
    try {
      final querySnapshot = await _firestore
          .collection('events')
          .orderBy('start_date')
          .get();

      final events = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return EventEntity(
          id: doc.id,
          title: data['title'] ?? '',
          description: data['description'] ?? '',
          startDate: (data['start_date'] as Timestamp).toDate(),
          capacity: data['capacity'] ?? 0,
          inscriptionCount: data['inscription_count'] ?? 0,
          status: data['status'] ?? '',
        );
      }).toList();

      return events.where((event) => event.status == 'active').toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<EventEntity?> getEventById(String eventId) async {
    try {
      final doc = await _firestore.collection('events').doc(eventId).get();
      
      if (!doc.exists) return null;
      
      final data = doc.data()!;
      return EventEntity(
        id: doc.id,
        title: data['title'] ?? '',
        description: data['description'] ?? '',
        startDate: (data['start_date'] as Timestamp).toDate(),
        capacity: data['capacity'] ?? 0,
        inscriptionCount: data['inscription_count'] ?? 0,
        status: data['status'] ?? '',
      );
    } catch (e) {
      throw Exception('Error al obtener evento: $e');
    }
  }

  @override
  Future<InscriptionEntity> inscribeToEvent(String eventId, String userId, String userName) async {
    try {
      final inscriptionRef = _firestore
          .collection('events')
          .doc(eventId)
          .collection('inscriptions')
          .doc();
      final eventRef = _firestore.collection('events').doc(eventId);

      await _firestore.runTransaction((transaction) async {
        final eventDoc = await transaction.get(eventRef);
        
        if (!eventDoc.exists) {
          throw Exception('El evento no existe');
        }

        final eventData = eventDoc.data()!;
        final currentCount = eventData['inscription_count'] ?? 0;
        final capacity = eventData['capacity'] ?? 0;

        if (currentCount >= capacity) {
          final status = 'En lista de espera';
          final inscriptionData = {
            'userId': userId,
            'userName': userName,
            'status': status,
          };
          transaction.set(inscriptionRef, inscriptionData);
          
          return InscriptionEntity(
            id: inscriptionRef.id,
            eventId: eventId,
            userId: userId,
            userName: userName,
            status: status,
          );
        }

        final inscriptionData = {
          'userId': userId,
          'userName': userName,
          'status': 'Confirmado',
        };

        transaction.set(inscriptionRef, inscriptionData);
        transaction.update(eventRef, {
          'inscription_count': currentCount + 1,
        });
      });

      final inscriptionDoc = await inscriptionRef.get();
      final data = inscriptionDoc.data()!;
      
      return InscriptionEntity(
        id: inscriptionDoc.id,
        eventId: eventId,
        userId: data['userId'],
        userName: data['userName'],
        status: data['status'],
      );
    } catch (e) {
      throw Exception('Error al inscribirse al evento: $e');
    }
  }

  @override
  Future<List<InscriptionEntity>> getUserInscriptions(String userId) async {
    try {
      final List<InscriptionEntity> allInscriptions = [];
      
      final eventsSnapshot = await _firestore.collection('events').get();
      
      for (final eventDoc in eventsSnapshot.docs) {
        final inscriptionsSnapshot = await _firestore
            .collection('events')
            .doc(eventDoc.id)
            .collection('inscriptions')
            .where('userId', isEqualTo: userId)
            .get();
            
        for (final inscriptionDoc in inscriptionsSnapshot.docs) {
          final data = inscriptionDoc.data();
          allInscriptions.add(InscriptionEntity(
            id: inscriptionDoc.id,
            eventId: eventDoc.id,
            userId: data['userId'],
            userName: data['userName'],
            status: data['status'],
          ));
        }
      }
      
      return allInscriptions;
    } catch (e) {
      throw Exception('Error al obtener inscripciones: $e');
    }
  }

  @override
  Future<bool> isUserInscribed(String eventId, String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('inscriptions')
          .where('eventId', isEqualTo: eventId)
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'registered')
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      throw Exception('Error verificando inscripción: $e');
    }
  }

  @override
  Future<void> markAttendance(String eventId, String qrCode) async {
    try {
      final querySnapshot = await _firestore
          .collection('inscriptions')
          .where('eventId', isEqualTo: eventId)
          .where('qrCode', isEqualTo: qrCode)
          .where('status', isEqualTo: 'registered')
          .get();

      if (querySnapshot.docs.isEmpty) {
        throw Exception('Código QR no válido o ya procesado');
      }

      final inscriptionDoc = querySnapshot.docs.first;
      await inscriptionDoc.reference.update({
        'status': 'attended',
        'attendedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error registrando asistencia: $e');
    }
  }
}