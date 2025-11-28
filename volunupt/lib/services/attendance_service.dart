import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import 'event_service.dart';

// Resultado de verificación para check-in por coordinador
class CheckInEligibility {
  final bool allowed;
  final String? reason;
  final SubEventModel? subEvent;
  final EventModel? event;

  const CheckInEligibility({
    required this.allowed,
    this.reason,
    this.subEvent,
    this.event,
  });
}

class AttendanceService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _attendanceRecordsCollection = 'attendanceRecords';
  static const String _subEventsCollection = 'subEvents';
  static const String _registrationsCollection = 'registrations';
  static const String _eventsCollection = 'events';


  // Registrar check-in de estudiante mediante QR
  static Future<String> checkInStudent({
    required String userId,
    required String qrCodeData,
  }) async {
    try {
      // Parsear datos del QR (formato: "subevent:subEventId:timestamp")
      final qrParts = qrCodeData.split(':');
      if (qrParts.length != 3 || qrParts[0] != 'subevent') {
        throw Exception('Código QR inválido');
      }

      final subEventId = qrParts[1];
      
      // Verificar que el subevento existe
      final subEventDoc = await _firestore
          .collection(_subEventsCollection)
          .doc(subEventId)
          .get();

      if (!subEventDoc.exists) {
        throw Exception('El evento no existe');
      }

      final subEvent = SubEventModel.fromSnapshot(subEventDoc);
      
      // Verificar que el usuario esté inscrito en la actividad o en el programa
      final isRegisteredToSub = await _isUserRegisteredForSubEvent(userId, subEventId);
      final isRegisteredToEvent = await _isUserRegisteredForEvent(userId, subEvent.baseEventId);
      if (!isRegisteredToSub && !isRegisteredToEvent) {
        throw Exception('No estás inscrito en el programa');
      }

      // Verificar que no haya un check-in previo
      final existingRecord = await _getExistingAttendanceRecord(userId, subEventId);
      if (existingRecord != null) {
        throw Exception('Ya has registrado tu asistencia para este evento');
      }

      // Verificar que el evento esté en horario válido (dentro de 1 hora antes y 2 horas después)
      final now = DateTime.now();
      final eventStart = subEvent.startTime;
      final eventEnd = subEvent.endTime;
      
      final checkInWindow = eventStart.subtract(const Duration(hours: 1));
      final checkOutWindow = eventEnd.add(const Duration(hours: 2));
      
      if (now.isBefore(checkInWindow)) {
        throw Exception('Aún no puedes registrar tu asistencia. El check-in abre 1 hora antes del evento.');
      }
      
      if (now.isAfter(checkOutWindow)) {
        throw Exception('El tiempo para registrar asistencia ha expirado.');
      }

      // Crear registro de asistencia
      final attendanceRecord = AttendanceRecordModel(
        recordId: '', // Se asignará automáticamente
        userId: userId,
        subEventId: subEventId,
        baseEventId: subEvent.baseEventId,
        sessionId: _generateSessionId(subEventId, now),
        checkInTime: now,
        status: AttendanceStatus.checkedIn,
        hoursEarned: 0.0, // Se asignará cuando el coordinador valide
        attendanceMethod: AttendanceMethod.qrScan,
      );

      final docRef = await _firestore
          .collection(_attendanceRecordsCollection)
          .add(attendanceRecord.toMap());

      return docRef.id;
    } catch (e) {
      throw Exception('Error al registrar asistencia: $e');
    }
  }

  static Future<int> countPendingAttendanceForCoordinator(String coordinatorId) async {
    final events = await _firestore
        .collection(_eventsCollection)
        .where('coordinatorId', isEqualTo: coordinatorId)
        .get();
    final eventIds = events.docs.map((d) => d.id).toList();
    if (eventIds.isEmpty) return 0;

    int total = 0;
    const chunkSize = 10;
    for (var i = 0; i < eventIds.length; i += chunkSize) {
      final chunk = eventIds.sublist(i, i + chunkSize > eventIds.length ? eventIds.length : i + chunkSize);
      final q = await _firestore
          .collection(_attendanceRecordsCollection)
          .where('baseEventId', whereIn: chunk)
          .where('status', isEqualTo: AttendanceStatus.checkedIn.toString().split('.').last)
          .get();
      total += q.docs.length;
    }
    return total;
  }

  static Future<int> countPendingAttendanceAll() async {
    final q = await _firestore
        .collection(_attendanceRecordsCollection)
        .where('status', isEqualTo: AttendanceStatus.checkedIn.toString().split('.').last)
        .get();
    return q.docs.length;
  }

  // Obtener registros de asistencia de un subevento
  static Stream<List<AttendanceRecordModel>> getSubEventAttendance(String subEventId) {
    return _firestore
        .collection(_attendanceRecordsCollection)
        .where('subEventId', isEqualTo: subEventId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AttendanceRecordModel.fromSnapshot(doc))
            .toList());
  }

  // Verificar si un usuario está inscrito en un subevento
  static Future<bool> _isUserRegisteredForSubEvent(String userId, String subEventId) async {
    try {
      final registrationQuery = await _firestore
          .collection(_registrationsCollection)
          .where('userId', isEqualTo: userId)
          .where('subEventId', isEqualTo: subEventId)
          .get();

      return registrationQuery.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Verificar si un usuario está inscrito en el programa (evento base)
  static Future<bool> _isUserRegisteredForEvent(String userId, String baseEventId) async {
    try {
      final registrationQuery = await _firestore
          .collection(_registrationsCollection)
          .where('userId', isEqualTo: userId)
          .where('baseEventId', isEqualTo: baseEventId)
          .where('subEventId', isEqualTo: '')
          .get();

      return registrationQuery.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Obtener registro de asistencia existente
  static Future<AttendanceRecordModel?> _getExistingAttendanceRecord(String userId, String subEventId) async {
    try {
      final query = await _firestore
          .collection(_attendanceRecordsCollection)
          .where('userId', isEqualTo: userId)
          .where('subEventId', isEqualTo: subEventId)
          .get();

      if (query.docs.isNotEmpty) {
        return AttendanceRecordModel.fromSnapshot(query.docs.first);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Generar ID de sesión único
  static String _generateSessionId(String subEventId, DateTime checkInTime) {
    return '${subEventId}_${checkInTime.millisecondsSinceEpoch}';
  }

  // Obtener registros de asistencia pendientes para un coordinador
  static Stream<List<AttendanceRecordModel>> getPendingAttendanceForCoordinator(String coordinatorId) {
    return _firestore
        .collection(_attendanceRecordsCollection)
        .where('status', isEqualTo: AttendanceStatus.checkedIn.toString().split('.').last)
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

  // Obtener registros de asistencia para validación, con filtros por estado
  static Stream<List<AttendanceRecordModel>> getAttendanceForValidation({
    required String coordinatorId,
    String? status,
  }) {
    // Mapear los estados esperados por la UI a los valores del enum/Firestore
    String? mappedStatus;
    switch (status) {
      case 'pending':
        mappedStatus = AttendanceStatus.checkedIn.toString().split('.').last;
        break;
      case 'confirmed':
        mappedStatus = AttendanceStatus.validated.toString().split('.').last;
        break;
      case 'rejected':
        mappedStatus = AttendanceStatus.absent.toString().split('.').last;
        break;
      default:
        mappedStatus = null; // 'all'
    }

    // Hacemos una consulta base y filtramos por estado si corresponde
    final baseQuery = _firestore.collection(_attendanceRecordsCollection);
    final stream = mappedStatus != null
        ? baseQuery.where('status', isEqualTo: mappedStatus).snapshots()
        : baseQuery.snapshots();

    return stream.asyncMap((snapshot) async {
      List<AttendanceRecordModel> records = [];

      for (final doc in snapshot.docs) {
        final record = AttendanceRecordModel.fromSnapshot(doc);

        // Verificar permisos del coordinador para el evento
        final eventDoc = await _firestore
            .collection(_eventsCollection)
            .doc(record.baseEventId)
            .get();

        if (!eventDoc.exists) continue;
        final event = EventModel.fromSnapshot(eventDoc);
        if (event.coordinatorId != coordinatorId) continue;

        records.add(record);
      }

      return records;
    });
  }

  // Validar asistencia (para coordinadores)
  static Future<void> validateAttendance({
    required String recordId,
    required double hoursEarned,
    required String coordinatorId,
    String? notes,
  }) async {
    try {
      await _firestore.collection(_attendanceRecordsCollection).doc(recordId).update({
        'status': AttendanceStatus.validated.toString().split('.').last,
        'hoursEarned': hoursEarned,
        'validatedBy': coordinatorId,
        'validatedAt': Timestamp.fromDate(DateTime.now()),
        'coordinatorNotes': notes ?? '',
      });

      // Actualizar total de horas del usuario
      final recordDoc = await _firestore
          .collection(_attendanceRecordsCollection)
          .doc(recordId)
          .get();
      
      if (recordDoc.exists) {
        final record = AttendanceRecordModel.fromSnapshot(recordDoc);
        await _updateUserTotalHours(record.userId, hoursEarned);
      }
    } catch (e) {
      throw Exception('Error al validar asistencia: $e');
    }
  }

  // Rechazar asistencia (para coordinadores)
  static Future<void> rejectAttendance({
    required String recordId,
    required String coordinatorId,
    String? reason,
  }) async {
    try {
      await _firestore.collection(_attendanceRecordsCollection).doc(recordId).update({
        'status': AttendanceStatus.absent.toString().split('.').last,
        'validatedBy': coordinatorId,
        'validatedAt': Timestamp.fromDate(DateTime.now()),
        'coordinatorNotes': reason ?? 'Asistencia rechazada',
      });
    } catch (e) {
      throw Exception('Error al rechazar asistencia: $e');
    }
  }

  // Actualizar total de horas del usuario
  static Future<void> _updateUserTotalHours(String userId, double additionalHours) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'totalHours': FieldValue.increment(additionalHours),
      });
    } catch (e) {
      // Error silencioso para no interrumpir el flujo principal
      debugPrint('Advertencia: No se pudo actualizar el total de horas del usuario: $e');
    }
  }

  // Obtener información de check-in para mostrar al usuario
  static Future<Map<String, dynamic>> getCheckInInfo(String qrCodeData) async {
    try {
      final qrParts = qrCodeData.split(':');
      if (qrParts.length != 3 || qrParts[0] != 'subevent') {
        throw Exception('Código QR inválido');
      }

      final subEventId = qrParts[1];
      
      // Obtener información del subevento
      final subEventDoc = await _firestore
          .collection(_subEventsCollection)
          .doc(subEventId)
          .get();

      if (!subEventDoc.exists) {
        throw Exception('El evento no existe');
      }

      final subEvent = SubEventModel.fromSnapshot(subEventDoc);
      
      // Obtener información del evento base
      final eventDoc = await _firestore
          .collection(_eventsCollection)
          .doc(subEvent.baseEventId)
          .get();

      EventModel? event;
      if (eventDoc.exists) {
        event = EventModel.fromSnapshot(eventDoc);
      }

      return {
        'subEvent': subEvent,
        'event': event,
        'isValid': true,
      };
    } catch (e) {
      return {
        'subEvent': null,
        'event': null,
        'isValid': false,
        'error': e.toString(),
      };
    }
  }

  // Verificar si un usuario puede hacer check-in
  static Future<Map<String, dynamic>> canUserCheckIn(String userId, String qrCodeData) async {
    try {
      final qrParts = qrCodeData.split(':');
      if (qrParts.length != 3 || qrParts[0] != 'subevent') {
        return {
          'canCheckIn': false,
          'reason': 'Código QR inválido',
        };
      }

      final subEventId = qrParts[1];
      
      // Verificar inscripción en actividad o programa
      final isRegisteredToSub = await _isUserRegisteredForSubEvent(userId, subEventId);
      final subEventDoc = await _firestore
          .collection(_subEventsCollection)
          .doc(subEventId)
          .get();
      if (!subEventDoc.exists) {
        return {
          'canCheckIn': false,
          'reason': 'El evento no existe',
        };
      }
      final subEvent = SubEventModel.fromSnapshot(subEventDoc);
      final isRegisteredToEvent = await _isUserRegisteredForEvent(userId, subEvent.baseEventId);
      if (!isRegisteredToSub && !isRegisteredToEvent) {
        return {
          'canCheckIn': false,
          'reason': 'No estás inscrito en el programa',
        };
      }

      // Verificar check-in previo
      final existingRecord = await _getExistingAttendanceRecord(userId, subEventId);
      if (existingRecord != null) {
        return {
          'canCheckIn': false,
          'reason': 'Ya has registrado tu asistencia para este evento',
          'existingRecord': existingRecord,
        };
      }

      // Verificar horario
      // subEvent ya obtenido arriba
      final now = DateTime.now();
      final checkInWindow = subEvent.startTime.subtract(const Duration(hours: 1));
      final checkOutWindow = subEvent.endTime.add(const Duration(hours: 2));
      
      if (now.isBefore(checkInWindow)) {
        return {
          'canCheckIn': false,
          'reason': 'Aún no puedes registrar tu asistencia. El check-in abre 1 hora antes del evento.',
        };
      }
      
      if (now.isAfter(checkOutWindow)) {
        return {
          'canCheckIn': false,
          'reason': 'El tiempo para registrar asistencia ha expirado.',
        };
      }

      return {
        'canCheckIn': true,
        'subEvent': subEvent,
      };
    } catch (e) {
      return {
        'canCheckIn': false,
        'reason': 'Error al verificar elegibilidad: $e',
      };
    }
  }

  // Obtener estadísticas de asistencia para un evento (coordinadores)
  static Future<Map<String, dynamic>> getEventAttendanceStats(String eventId) async {
    try {
      final attendanceRecords = await _firestore
          .collection(_attendanceRecordsCollection)
          .where('baseEventId', isEqualTo: eventId)
          .get();

      int totalCheckIns = 0;
      int validatedAttendances = 0;
      int pendingValidations = 0;
      int rejectedAttendances = 0;
      double totalHoursAssigned = 0.0;

      for (final doc in attendanceRecords.docs) {
        final record = AttendanceRecordModel.fromSnapshot(doc);
        totalCheckIns++;

        switch (record.status) {
          case AttendanceStatus.validated:
            validatedAttendances++;
            totalHoursAssigned += record.hoursEarned;
            break;
          case AttendanceStatus.checkedIn:
            pendingValidations++;
            break;
          case AttendanceStatus.absent:
            rejectedAttendances++;
            break;
        }
      }

      return {
        'totalCheckIns': totalCheckIns,
        'validatedAttendances': validatedAttendances,
        'pendingValidations': pendingValidations,
        'rejectedAttendances': rejectedAttendances,
        'totalHoursAssigned': totalHoursAssigned,
        'validationRate': totalCheckIns > 0 ? (validatedAttendances / totalCheckIns) * 100 : 0.0,
      };
    } catch (e) {
      throw Exception('Error al obtener estadísticas de asistencia: $e');
    }
  }

  // Verificar si un coordinador puede pasar asistencia a un estudiante en una actividad
  static Future<CheckInEligibility> canCoordinatorCheckInStudent({
    required String coordinatorId,
    required String eventId,
    required String subEventId,
    required String studentId,
  }) async {
    try {
      // Obtener subevento
      final subEventDoc = await _firestore.collection(_subEventsCollection).doc(subEventId).get();
      if (!subEventDoc.exists) {
        return CheckInEligibility(allowed: false, reason: 'La actividad no existe');
      }
      final subEvent = SubEventModel.fromSnapshot(subEventDoc);

      // Obtener evento base
      final eventDoc = await _firestore.collection(_eventsCollection).doc(eventId).get();
      if (!eventDoc.exists) {
        return CheckInEligibility(allowed: false, reason: 'El programa no existe');
      }
      final event = EventModel.fromSnapshot(eventDoc);

      // Validar que el subevento pertenezca al evento indicado
      if (subEvent.baseEventId != eventId) {
        return CheckInEligibility(allowed: false, reason: 'La actividad no pertenece al programa');
      }

      // Validar permisos del coordinador o administrador
      debugPrint('🔍 ===== VALIDACIÓN DE PERMISOS =====');
      debugPrint('🔍 Evento: "${event.title}" (ID: ${event.eventId})');
      debugPrint('🔍 Coordinator ID del evento: ${event.coordinatorId}');
      debugPrint('🔍 Usuario actual (coordinatorId): $coordinatorId');
      
      // Primero verificar si es el coordinador del evento
      bool isCoordinator = event.coordinatorId == coordinatorId;
      debugPrint('🔍 ¿Es coordinador del evento? $isCoordinator');
      
      // Si no es el coordinador del evento, verificar si es administrador
      if (!isCoordinator) {
        debugPrint('🔍 No es coordinador del evento, verificando si es administrador...');
        try {
          final userDoc = await _firestore.collection('users').doc(coordinatorId).get();
          if (userDoc.exists) {
            final userData = userDoc.data();
            final role = userData?['role']?.toString().toLowerCase() ?? '';
            
            debugPrint('🔍 Rol obtenido de Firestore: "$role"');
            debugPrint('🔍 Datos completos del usuario: ${userData?.keys.toList()}');
            
            // Si es administrador, permitir acceso
            if (role == 'administrador') {
              debugPrint('✅ Usuario es ADMINISTRADOR, permitiendo acceso a todos los eventos');
              isCoordinator = true;
            } else {
              debugPrint('❌ Usuario NO es administrador. Rol encontrado: "$role"');
              debugPrint('❌ También NO es coordinador de este evento específico');
            }
          } else {
            debugPrint('❌ Documento de usuario NO existe en Firestore para UID: $coordinatorId');
          }
        } catch (e) {
          debugPrint('❌ Error al verificar rol de usuario: $e');
        }
      } else {
        debugPrint('✅ Usuario ES el coordinador de este evento');
      }
      
      if (!isCoordinator) {
        debugPrint('❌ ===== ACCESO DENEGADO =====');
        debugPrint('❌ Razón: No eres el coordinador de este evento ni administrador');
        return CheckInEligibility(
          allowed: false, 
          reason: 'No tienes permisos para este programa. Solo el coordinador que lo creó o un administrador pueden pasar asistencia.',
        );
      }
      
      debugPrint('✅ ===== PERMISOS VALIDADOS CORRECTAMENTE =====');

      // Verificar inscripción del estudiante en actividad o programa
      final isRegisteredToSub = await _isUserRegisteredForSubEvent(studentId, subEventId);
      final isRegisteredToEvent = await _isUserRegisteredForEvent(studentId, eventId);
      if (!isRegisteredToSub && !isRegisteredToEvent) {
        return CheckInEligibility(allowed: false, reason: 'El estudiante no está inscrito en el programa', subEvent: subEvent, event: event);
      }

      // Verificar si ya tiene un registro de asistencia
      final existing = await _getExistingAttendanceRecord(studentId, subEventId);
      if (existing != null) {
        return CheckInEligibility(allowed: false, reason: 'El estudiante ya registró asistencia en esta actividad', subEvent: subEvent, event: event);
      }

      // Verificar ventana horaria (mismo criterio que escaneo del estudiante)
      final now = DateTime.now();
      final checkInWindow = subEvent.startTime.subtract(const Duration(hours: 1));
      final checkOutWindow = subEvent.endTime.add(const Duration(hours: 2));
      if (now.isBefore(checkInWindow)) {
        return CheckInEligibility(allowed: false, reason: 'Aún no inicia el periodo de asistencia para esta actividad', subEvent: subEvent, event: event);
      }
      if (now.isAfter(checkOutWindow)) {
        return CheckInEligibility(allowed: false, reason: 'El periodo de asistencia ya finalizó', subEvent: subEvent, event: event);
      }

      return CheckInEligibility(allowed: true, subEvent: subEvent, event: event);
    } catch (e) {
      return CheckInEligibility(allowed: false, reason: 'Error al verificar elegibilidad: $e');
    }
  }

  // Registrar asistencia por parte de coordinador (escaneo del QR del estudiante)
  static Future<String> coordinatorCheckInStudent({
    required String coordinatorId,
    required String eventId,
    required String subEventId,
    required String studentId,
  }) async {
    try {
      final can = await canCoordinatorCheckInStudent(
        coordinatorId: coordinatorId,
        eventId: eventId,
        subEventId: subEventId,
        studentId: studentId,
      );
      if (!can.allowed) {
        throw Exception(can.reason ?? 'No autorizado para registrar asistencia');
      }

      final subEvent = can.subEvent!;
      final now = DateTime.now();

      final record = AttendanceRecordModel(
        recordId: '',
        userId: studentId,
        subEventId: subEventId,
        baseEventId: subEvent.baseEventId,
        sessionId: _generateSessionId(subEventId, now),
        checkInTime: now,
        status: AttendanceStatus.checkedIn,
        hoursEarned: 0.0,
        attendanceMethod: AttendanceMethod.qrScan,
        validatedBy: null,
        validatedAt: null,
        coordinatorNotes: null,
      );

      final docRef = await _firestore
          .collection(_attendanceRecordsCollection)
          .add(record.toMap());

      return docRef.id;
    } catch (e) {
      throw Exception('Error al registrar asistencia: $e');
    }
  }

  // Registrar asistencia por parte de coordinador desde listado (sin escaneo de QR)
  static Future<String> coordinatorManualCheckInStudent({
    required String coordinatorId,
    required String eventId,
    required String subEventId,
    required String studentId,
  }) async {
    try {
      // Reutilizar la misma validación de permisos, horario e inscripción
      final can = await canCoordinatorCheckInStudent(
        coordinatorId: coordinatorId,
        eventId: eventId,
        subEventId: subEventId,
        studentId: studentId,
      );
      if (!can.allowed) {
        throw Exception(can.reason ?? 'No autorizado para registrar asistencia');
      }

      final subEvent = can.subEvent!;
      final now = DateTime.now();

      final record = AttendanceRecordModel(
        recordId: '',
        userId: studentId,
        subEventId: subEventId,
        baseEventId: subEvent.baseEventId,
        sessionId: _generateSessionId(subEventId, now),
        checkInTime: now,
        status: AttendanceStatus.checkedIn,
        hoursEarned: 0.0,
        attendanceMethod: AttendanceMethod.manualList,
        validatedBy: null,
        validatedAt: null,
        coordinatorNotes: null,
      );

      final docRef = await _firestore
          .collection(_attendanceRecordsCollection)
          .add(record.toMap());

      return docRef.id;
    } catch (e) {
      throw Exception('Error al registrar asistencia manual: $e');
    }
  }

  /// Calcular horas basadas en la duración de una actividad
  static double _calculateHoursForActivity(SubEventModel subEvent) {
    final duration = subEvent.endTime.difference(subEvent.startTime);
    return duration.inMinutes / 60.0; // Convertir minutos a horas
  }

  /// Asignar horas automáticamente a todos los inscritos cuando una actividad finalice
  /// Solo asigna a los que no tienen un registro de asistencia validada
  static Future<void> autoAssignHoursForCompletedActivity({
    required String subEventId,
  }) async {
    try {
      // Obtener la actividad
      final subEventDoc = await _firestore
          .collection(_subEventsCollection)
          .doc(subEventId)
          .get();
      
      if (!subEventDoc.exists) {
        debugPrint('⚠️ Actividad no existe: $subEventId');
        return;
      }

      final subEvent = SubEventModel.fromSnapshot(subEventDoc);
      final now = DateTime.now();
      
      // Verificar que la actividad ya finalizó
      if (subEvent.endTime.isAfter(now)) {
        debugPrint('⚠️ La actividad aún no ha finalizado: $subEventId');
        return;
      }

      // Obtener todas las inscripciones a esta actividad
      final registrationsQuery = await _firestore
          .collection(_registrationsCollection)
          .where('subEventId', isEqualTo: subEventId)
          .get();

      // También obtener inscripciones al programa (baseEventId) sin subEventId específico
      final eventRegistrationsQuery = await _firestore
          .collection(_registrationsCollection)
          .where('baseEventId', isEqualTo: subEvent.baseEventId)
          .where('subEventId', isEqualTo: '')
          .get();

      // Combinar todos los usuarios inscritos
      final Set<String> userIds = {};
      for (final doc in registrationsQuery.docs) {
        final userId = doc.data()['userId'] as String?;
        if (userId != null) userIds.add(userId);
      }
      for (final doc in eventRegistrationsQuery.docs) {
        final userId = doc.data()['userId'] as String?;
        if (userId != null) userIds.add(userId);
      }

      // Calcular horas para esta actividad
      final hoursEarned = _calculateHoursForActivity(subEvent);

      // Procesar cada usuario inscrito
      final batch = _firestore.batch();
      int assignedCount = 0;

      for (final userId in userIds) {
        // Verificar si ya tiene un registro de asistencia validada para esta actividad
        final existingAttendanceQuery = await _firestore
            .collection(_attendanceRecordsCollection)
            .where('userId', isEqualTo: userId)
            .where('subEventId', isEqualTo: subEventId)
            .where('status', isEqualTo: AttendanceStatus.validated.toString().split('.').last)
            .limit(1)
            .get();

        // Si ya tiene asistencia validada, saltar
        if (existingAttendanceQuery.docs.isNotEmpty) {
          continue;
        }

        // Crear registro de asistencia automática
        final record = AttendanceRecordModel(
          recordId: '',
          userId: userId,
          subEventId: subEventId,
          baseEventId: subEvent.baseEventId,
          sessionId: _generateSessionId(subEventId, subEvent.endTime),
          checkInTime: subEvent.endTime, // Usar la hora de finalización
          status: AttendanceStatus.validated,
          hoursEarned: hoursEarned,
          attendanceMethod: AttendanceMethod.manualList, // Marcado como automático
          validatedBy: 'system',
          validatedAt: now,
          coordinatorNotes: 'Asignación automática al finalizar la actividad',
        );

        final recordRef = _firestore
            .collection(_attendanceRecordsCollection)
            .doc();
        batch.set(recordRef, record.toMap());
        assignedCount++;
      }

      if (assignedCount > 0) {
        await batch.commit();
        debugPrint('✅ Asignadas horas automáticamente a $assignedCount usuarios para actividad: ${subEvent.title}');
      } else {
        debugPrint('ℹ️ No se asignaron horas (todos ya tienen asistencia validada) para actividad: ${subEvent.title}');
      }
    } catch (e) {
      debugPrint('❌ Error al asignar horas automáticamente para actividad $subEventId: $e');
      rethrow;
    }
  }

  /// Asignar horas automáticamente cuando un evento se complete
  /// Asigna las horas del evento padre a todos los inscritos
  static Future<void> autoAssignHoursForCompletedEvent({
    required String eventId,
  }) async {
    try {
      // Obtener el evento
      final eventDoc = await _firestore
          .collection(_eventsCollection)
          .doc(eventId)
          .get();
      
      if (!eventDoc.exists) {
        debugPrint('⚠️ Evento no existe: $eventId');
        return;
      }

      final event = EventModel.fromSnapshot(eventDoc);

      // Verificar que el evento esté completado
      final completed = await EventService.hasEventCompleted(eventId);
      if (!completed) {
        debugPrint('⚠️ El evento aún no ha finalizado: $eventId');
        return;
      }

      // Obtener todas las inscripciones al evento (programa)
      final registrationsQuery = await _firestore
          .collection(_registrationsCollection)
          .where('baseEventId', isEqualTo: eventId)
          .get();

      final Set<String> userIds = {};
      for (final doc in registrationsQuery.docs) {
        final userId = doc.data()['userId'] as String?;
        if (userId != null) userIds.add(userId);
      }

      // Obtener todas las actividades del evento
      final subEventsQuery = await _firestore
          .collection(_subEventsCollection)
          .where('baseEventId', isEqualTo: eventId)
          .get();

      final subEvents = subEventsQuery.docs
          .map((doc) => SubEventModel.fromSnapshot(doc))
          .toList();

      if (subEvents.isEmpty) {
        debugPrint('⚠️ El evento no tiene actividades: $eventId');
        return;
      }

      // Procesar cada usuario inscrito
      final batch = _firestore.batch();
      int totalAssigned = 0;

      for (final userId in userIds) {
        // Verificar si ya tiene las horas completas del evento
        final existingAttendanceQuery = await _firestore
            .collection(_attendanceRecordsCollection)
            .where('userId', isEqualTo: userId)
            .where('baseEventId', isEqualTo: eventId)
            .where('status', isEqualTo: AttendanceStatus.validated.toString().split('.').last)
            .get();

        double existingHours = 0.0;
        for (final doc in existingAttendanceQuery.docs) {
          final record = AttendanceRecordModel.fromSnapshot(doc);
          existingHours += record.hoursEarned;
        }

        // Calcular horas requeridas dinámicamente
        final requiredHours = await EventService.calculateTotalHours(eventId);

        // Si ya tiene las horas requeridas o más, saltar
        if (existingHours >= requiredHours) {
          continue;
        }

        // Calcular horas que faltan
        final hoursNeeded = requiredHours - existingHours;

        // Buscar actividades que no tengan registro de asistencia
        for (final subEvent in subEvents) {
          // Verificar si ya tiene asistencia para esta actividad
          final hasAttendance = existingAttendanceQuery.docs.any((doc) {
            final record = AttendanceRecordModel.fromSnapshot(doc);
            return record.subEventId == subEvent.subEventId;
          });

          if (!hasAttendance && hoursNeeded > 0) {
            // Asignar horas de esta actividad (o parte si excede las horas necesarias)
            final activityHours = _calculateHoursForActivity(subEvent);
            final hoursToAssign = activityHours <= hoursNeeded 
                ? activityHours 
                : hoursNeeded;

            final record = AttendanceRecordModel(
              recordId: '',
              userId: userId,
              subEventId: subEvent.subEventId,
              baseEventId: eventId,
              sessionId: _generateSessionId(subEvent.subEventId, subEvent.endTime),
              checkInTime: subEvent.endTime,
              status: AttendanceStatus.validated,
              hoursEarned: hoursToAssign,
              attendanceMethod: AttendanceMethod.manualList,
              validatedBy: 'system',
              validatedAt: DateTime.now(),
              coordinatorNotes: 'Asignación automática al completar el evento',
            );

            final recordRef = _firestore
                .collection(_attendanceRecordsCollection)
                .doc();
            batch.set(recordRef, record.toMap());
            totalAssigned++;
            
            // Si ya alcanzamos las horas necesarias, salir
            if (hoursToAssign >= hoursNeeded) {
              break;
            }
          }
        }
      }

      if (totalAssigned > 0) {
        await batch.commit();
        debugPrint('✅ Asignadas horas automáticamente a $totalAssigned registros para evento completado: ${event.title}');
      } else {
        debugPrint('ℹ️ No se asignaron horas adicionales (todos ya tienen las horas completas) para evento: ${event.title}');
      }
    } catch (e) {
      debugPrint('❌ Error al asignar horas automáticamente para evento $eventId: $e');
      rethrow;
    }
  }

  /// Verificar y asignar horas automáticamente para actividades finalizadas
  /// Esta función debe llamarse periódicamente o cuando se actualice una actividad
  static Future<void> checkAndAutoAssignHoursForCompletedActivities({
    required String eventId,
  }) async {
    try {
      // Obtener todas las actividades del evento
      final subEventsQuery = await _firestore
          .collection(_subEventsCollection)
          .where('baseEventId', isEqualTo: eventId)
          .get();

      final now = DateTime.now();

      for (final doc in subEventsQuery.docs) {
        final subEvent = SubEventModel.fromSnapshot(doc);
        
        // Si la actividad ya finalizó, asignar horas automáticamente
        if (subEvent.endTime.isBefore(now)) {
          await autoAssignHoursForCompletedActivity(subEventId: subEvent.subEventId);
        }
      }

      // Verificar si el evento está completado y asignar horas si es necesario
      final completed = await EventService.hasEventCompleted(eventId);
      if (completed) {
        // Marcar el evento como completado
        await EventService.updateEventStatus(eventId, EventStatus.completado);
        
        // Asignar horas automáticas del evento
        await autoAssignHoursForCompletedEvent(eventId: eventId);
      }
    } catch (e) {
      debugPrint('❌ Error al verificar y asignar horas automáticas: $e');
      rethrow;
    }
  }
}