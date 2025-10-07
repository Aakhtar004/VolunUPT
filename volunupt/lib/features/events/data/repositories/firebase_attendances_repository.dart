import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/attendance_entity.dart';
import '../../domain/repositories/attendances_repository.dart';

class FirebaseAttendancesRepository implements AttendancesRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<List<AttendanceEntity>> getEventAttendances(String eventId) async {
    try {
      final snapshot = await _firestore
          .collection('events')
          .doc(eventId)
          .collection('attendances')
          .orderBy('scanned_at', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return AttendanceEntity(
          id: doc.id,
          userId: data['userId'] ?? '',
          userName: data['userName'] ?? '',
          sessionId: data['sessionId'] ?? '',
          scannedAt: (data['scanned_at'] as Timestamp).toDate(),
          recordedByName: data['recorded_by_name'] ?? '',
        );
      }).toList();
    } catch (e) {
      throw Exception('Error al obtener asistencias: $e');
    }
  }

  @override
  Future<List<AttendanceEntity>> getSessionAttendances(String eventId, String sessionId) async {
    try {
      final snapshot = await _firestore
          .collection('events')
          .doc(eventId)
          .collection('attendances')
          .where('sessionId', isEqualTo: sessionId)
          .orderBy('scanned_at', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return AttendanceEntity(
          id: doc.id,
          userId: data['userId'] ?? '',
          userName: data['userName'] ?? '',
          sessionId: data['sessionId'] ?? '',
          scannedAt: (data['scanned_at'] as Timestamp).toDate(),
          recordedByName: data['recorded_by_name'] ?? '',
        );
      }).toList();
    } catch (e) {
      throw Exception('Error al obtener asistencias de la sesión: $e');
    }
  }

  @override
  Future<AttendanceEntity?> getAttendance(String eventId, String attendanceId) async {
    try {
      final doc = await _firestore
          .collection('events')
          .doc(eventId)
          .collection('attendances')
          .doc(attendanceId)
          .get();

      if (!doc.exists) return null;

      final data = doc.data()!;
      return AttendanceEntity(
        id: doc.id,
        userId: data['userId'] ?? '',
        userName: data['userName'] ?? '',
        sessionId: data['sessionId'] ?? '',
        scannedAt: (data['scanned_at'] as Timestamp).toDate(),
        recordedByName: data['recorded_by_name'] ?? '',
      );
    } catch (e) {
      throw Exception('Error al obtener asistencia: $e');
    }
  }

  @override
  Future<void> recordAttendance(String eventId, AttendanceEntity attendance) async {
    try {
      await _firestore
          .collection('events')
          .doc(eventId)
          .collection('attendances')
          .doc(attendance.id)
          .set({
        'userId': attendance.userId,
        'userName': attendance.userName,
        'sessionId': attendance.sessionId,
        'scanned_at': Timestamp.fromDate(attendance.scannedAt),
        'recorded_by_name': attendance.recordedByName,
      });
    } catch (e) {
      throw Exception('Error al registrar asistencia: $e');
    }
  }

  @override
  Future<void> deleteAttendance(String eventId, String attendanceId) async {
    try {
      await _firestore
          .collection('events')
          .doc(eventId)
          .collection('attendances')
          .doc(attendanceId)
          .delete();
    } catch (e) {
      throw Exception('Error al eliminar asistencia: $e');
    }
  }
}