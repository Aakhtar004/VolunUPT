import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';

class HistoryService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _attendanceRecordsCollection = 'attendanceRecords';
  static const String _subEventsCollection = 'subEvents';
  static const String _eventsCollection = 'events';
  static const String _usersCollection = 'users';

  // Obtener historial de asistencia de un usuario
  static Stream<List<AttendanceRecordModel>> getUserAttendanceHistory(String userId) {
    return _firestore
        .collection(_attendanceRecordsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('checkInTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AttendanceRecordModel.fromSnapshot(doc))
            .toList());
  }

  // Obtener historial de asistencia filtrado por estado
  static Stream<List<AttendanceRecordModel>> getUserAttendanceByStatus(
    String userId, 
    AttendanceStatus status
  ) {
    return _firestore
        .collection(_attendanceRecordsCollection)
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: status.toString().split('.').last)
        .orderBy('checkInTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AttendanceRecordModel.fromSnapshot(doc))
            .toList());
  }

  // Obtener actividades recientes de un usuario (últimos 30 días)
  static Stream<List<AttendanceRecordModel>> getUserRecentActivities(String userId) {
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    
    return _firestore
        .collection(_attendanceRecordsCollection)
        .where('userId', isEqualTo: userId)
        .where('checkInTime', isGreaterThanOrEqualTo: Timestamp.fromDate(thirtyDaysAgo))
        .orderBy('checkInTime', descending: true)
        .limit(10)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AttendanceRecordModel.fromSnapshot(doc))
            .toList());
  }

  // Obtener total de horas confirmadas de un usuario
  static Future<double> getUserTotalConfirmedHours(String userId) async {
    try {
      final attendanceRecords = await _firestore
          .collection(_attendanceRecordsCollection)
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: AttendanceStatus.validated.toString().split('.').last)
          .get();

      double totalHours = 0.0;
      for (final doc in attendanceRecords.docs) {
        final record = AttendanceRecordModel.fromSnapshot(doc);
        totalHours += record.hoursEarned;
      }

      return totalHours;
    } catch (e) {
      throw Exception('Error al calcular horas totales: $e');
    }
  }

  // Obtener estadísticas de asistencia de un usuario
  static Future<Map<String, dynamic>> getUserAttendanceStats(String userId) async {
    try {
      final attendanceRecords = await _firestore
          .collection(_attendanceRecordsCollection)
          .where('userId', isEqualTo: userId)
          .get();

      int totalActivities = attendanceRecords.docs.length;
      int confirmedActivities = 0;
      int pendingActivities = 0;
      double totalHours = 0.0;
      double confirmedHours = 0.0;

      for (final doc in attendanceRecords.docs) {
        final record = AttendanceRecordModel.fromSnapshot(doc);
        totalHours += record.hoursEarned;

        if (record.status == AttendanceStatus.validated) {
          confirmedActivities++;
          confirmedHours += record.hoursEarned;
        } else if (record.status == AttendanceStatus.checkedIn) {
          pendingActivities++;
        }
      }

      // Calcular actividades en el último mes
      final lastMonth = DateTime.now().subtract(const Duration(days: 30));
      final recentActivities = attendanceRecords.docs.where((doc) {
        final record = AttendanceRecordModel.fromSnapshot(doc);
        return record.checkInTime.isAfter(lastMonth);
      }).length;

      return {
        'totalActivities': totalActivities,
        'confirmedActivities': confirmedActivities,
        'pendingActivities': pendingActivities,
        'totalHours': totalHours,
        'confirmedHours': confirmedHours,
        'recentActivities': recentActivities,
        'completionRate': totalActivities > 0 ? (confirmedActivities / totalActivities) * 100 : 0.0,
      };
    } catch (e) {
      throw Exception('Error al obtener estadísticas de asistencia: $e');
    }
  }

  // Obtener historial de asistencia de un subevento (para coordinadores)
  static Stream<List<AttendanceRecordModel>> getSubEventAttendanceHistory(String subEventId) {
    return _firestore
        .collection(_attendanceRecordsCollection)
        .where('subEventId', isEqualTo: subEventId)
        .orderBy('checkInTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AttendanceRecordModel.fromSnapshot(doc))
            .toList());
  }

  // Obtener historial de asistencia de un evento base (para coordinadores)
  static Stream<List<AttendanceRecordModel>> getEventAttendanceHistory(String eventId) {
    return _firestore
        .collection(_attendanceRecordsCollection)
        .where('baseEventId', isEqualTo: eventId)
        .orderBy('checkInTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AttendanceRecordModel.fromSnapshot(doc))
            .toList());
  }

  // Confirmar asistencia (para coordinadores)
  static Future<void> confirmAttendance(String recordId, double hoursEarned, String coordinatorId) async {
    try {
      await _firestore.collection(_attendanceRecordsCollection).doc(recordId).update({
        'status': AttendanceStatus.validated.toString().split('.').last,
        'hoursEarned': hoursEarned,
        'validatedBy': coordinatorId,
        'validatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Error al confirmar asistencia: $e');
    }
  }

  // Rechazar asistencia (para coordinadores)
  static Future<void> rejectAttendance(String recordId, String coordinatorId) async {
    try {
      await _firestore.collection(_attendanceRecordsCollection).doc(recordId).update({
        'status': AttendanceStatus.absent.toString().split('.').last,
        'validatedBy': coordinatorId,
        'validatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Error al rechazar asistencia: $e');
    }
  }

  // Obtener registros pendientes de confirmación (para coordinadores)
  static Stream<List<AttendanceRecordModel>> getPendingAttendanceRecords(String coordinatorId) {
    return _firestore
        .collection(_attendanceRecordsCollection)
        .where('status', isEqualTo: AttendanceStatus.checkedIn.toString().split('.').last)
        .orderBy('checkInTime', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          List<AttendanceRecordModel> pendingRecords = [];
          
          for (final doc in snapshot.docs) {
            final record = AttendanceRecordModel.fromSnapshot(doc);
            
            // Verificar si el coordinador tiene permisos para este evento
            final eventDoc = await _firestore
                .collection(_eventsCollection)
                .doc(record.baseEventId)
                .get();
            
            if (eventDoc.exists) {
              final event = EventModel.fromSnapshot(eventDoc);
              if (event.coordinatorId == coordinatorId) {
                pendingRecords.add(record);
              }
            }
          }
          
          return pendingRecords;
        });
  }

  // Obtener historial detallado con información de eventos y subeventos
  static Future<List<Map<String, dynamic>>> getUserDetailedHistory(String userId) async {
    try {
      final attendanceRecords = await _firestore
          .collection(_attendanceRecordsCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('checkInTime', descending: true)
          .get();

      List<Map<String, dynamic>> detailedHistory = [];

      for (final doc in attendanceRecords.docs) {
        final record = AttendanceRecordModel.fromSnapshot(doc);

        // Obtener información del subevento
        final subEventDoc = await _firestore
            .collection(_subEventsCollection)
            .doc(record.subEventId)
            .get();

        // Obtener información del evento base
        final eventDoc = await _firestore
            .collection(_eventsCollection)
            .doc(record.baseEventId)
            .get();

        String subEventName = 'Actividad sin nombre';
        String eventName = 'Evento sin nombre';

        if (subEventDoc.exists) {
          final subEventData = subEventDoc.data() as Map<String, dynamic>;
          subEventName = subEventData['title'] ?? 'Actividad sin nombre';
        }

        if (eventDoc.exists) {
          final eventData = eventDoc.data() as Map<String, dynamic>;
          eventName = eventData['title'] ?? 'Evento sin nombre';
        }

        detailedHistory.add({
          'attendance': record,
          'subEventName': subEventName,
          'eventName': eventName,
          'subEventId': record.subEventId,
          'baseEventId': record.baseEventId,
        });
      }

      return detailedHistory;
    } catch (e) {
      throw Exception('Error al obtener historial detallado: $e');
    }
  }

  // Exportar historial de un usuario (para generar reportes)
  static Future<Map<String, dynamic>> exportUserHistory(String userId) async {
    try {
      final detailedHistory = await getUserDetailedHistory(userId);
      final stats = await getUserAttendanceStats(userId);

      return {
        'userId': userId,
        'exportDate': DateTime.now().toIso8601String(),
        'statistics': stats,
        'activities': detailedHistory.map((item) => {
          'eventTitle': item['event']?.title ?? 'Evento eliminado',
          'subEventTitle': item['subEvent']?.title ?? 'Actividad eliminada',
          'date': item['subEvent']?.date?.toIso8601String() ?? '',
          'location': item['subEvent']?.location ?? '',
          'checkInTime': item['attendanceRecord'].checkInTime.toIso8601String(),
          'hoursWorked': item['attendanceRecord'].hoursWorked,
          'status': item['attendanceRecord'].status.toString().split('.').last,
          'coordinatorNotes': item['attendanceRecord'].coordinatorNotes,
        }).toList(),
      };
    } catch (e) {
      throw Exception('Error al exportar historial: $e');
    }
  }

  // Obtener ranking de usuarios por horas (para administradores)
  static Future<List<Map<String, dynamic>>> getUsersRanking({int limit = 10}) async {
    try {
      final users = await _firestore
          .collection(_usersCollection)
          .orderBy('totalHours', descending: true)
          .limit(limit)
          .get();

      return users.docs.map((doc) {
        final user = UserModel.fromSnapshot(doc);
        return {
          'user': user,
          'totalHours': user.totalHours,
        };
      }).toList();
    } catch (e) {
      throw Exception('Error al obtener ranking de usuarios: $e');
    }
  }
}