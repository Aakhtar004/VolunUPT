import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/session_entity.dart';
import '../../domain/repositories/sessions_repository.dart';

class FirebaseSessionsRepository implements SessionsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<List<SessionEntity>> getEventSessions(String eventId) async {
    try {
      final snapshot = await _firestore
          .collection('events')
          .doc(eventId)
          .collection('sessions')
          .orderBy('session_time')
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return SessionEntity(
          id: doc.id,
          title: data['title'] ?? '',
          sessionTime: (data['session_time'] as Timestamp).toDate(),
        );
      }).toList();
    } catch (e) {
      throw Exception('Error al obtener sesiones: $e');
    }
  }

  @override
  Future<SessionEntity?> getSession(String eventId, String sessionId) async {
    try {
      final doc = await _firestore
          .collection('events')
          .doc(eventId)
          .collection('sessions')
          .doc(sessionId)
          .get();

      if (!doc.exists) return null;

      final data = doc.data()!;
      return SessionEntity(
        id: doc.id,
        title: data['title'] ?? '',
        sessionTime: (data['session_time'] as Timestamp).toDate(),
      );
    } catch (e) {
      throw Exception('Error al obtener sesión: $e');
    }
  }

  @override
  Future<void> createSession(String eventId, SessionEntity session) async {
    try {
      await _firestore
          .collection('events')
          .doc(eventId)
          .collection('sessions')
          .doc(session.id)
          .set({
        'title': session.title,
        'session_time': Timestamp.fromDate(session.sessionTime),
      });
    } catch (e) {
      throw Exception('Error al crear sesión: $e');
    }
  }

  @override
  Future<void> updateSession(String eventId, SessionEntity session) async {
    try {
      await _firestore
          .collection('events')
          .doc(eventId)
          .collection('sessions')
          .doc(session.id)
          .update({
        'title': session.title,
        'session_time': Timestamp.fromDate(session.sessionTime),
      });
    } catch (e) {
      throw Exception('Error al actualizar sesión: $e');
    }
  }

  @override
  Future<void> deleteSession(String eventId, String sessionId) async {
    try {
      await _firestore
          .collection('events')
          .doc(eventId)
          .collection('sessions')
          .doc(sessionId)
          .delete();
    } catch (e) {
      throw Exception('Error al eliminar sesión: $e');
    }
  }
}