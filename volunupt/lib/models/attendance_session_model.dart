import 'package:cloud_firestore/cloud_firestore.dart';
import 'enums.dart';

class AttendanceSessionModel {
  final String sessionId;
  final String eventId; // ID del evento base
  final String? subEventId; // ID del subevento (null si es evento simple)
  final String coordinatorId; // ID del coordinador que maneja la sesión
  final DateTime sessionDate;
  final DateTime? startTime; // Hora de inicio de la sesión
  final DateTime? endTime; // Hora de finalización de la sesión
  final SessionStatus status;
  final double hoursToAssign; // Horas que se asignarán al finalizar
  final List<String> attendees; // Lista de userIds de asistentes
  final Map<String, DateTime> checkInTimes; // userId -> hora de check-in
  final Map<String, AttendanceMethod> attendanceMethods; // userId -> método usado
  final DateTime createdAt;
  final DateTime? updatedAt;

  AttendanceSessionModel({
    required this.sessionId,
    required this.eventId,
    this.subEventId,
    required this.coordinatorId,
    required this.sessionDate,
    this.startTime,
    this.endTime,
    required this.status,
    required this.hoursToAssign,
    required this.attendees,
    required this.checkInTimes,
    required this.attendanceMethods,
    required this.createdAt,
    this.updatedAt,
  });

  // Crear desde DocumentSnapshot de Firestore
  factory AttendanceSessionModel.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;
    
    return AttendanceSessionModel(
      sessionId: snapshot.id,
      eventId: data['eventId'] ?? '',
      subEventId: data['subEventId'],
      coordinatorId: data['coordinatorId'] ?? '',
      sessionDate: (data['sessionDate'] as Timestamp).toDate(),
      startTime: data['startTime'] != null 
          ? (data['startTime'] as Timestamp).toDate() 
          : null,
      endTime: data['endTime'] != null 
          ? (data['endTime'] as Timestamp).toDate() 
          : null,
      status: SessionStatus.values.firstWhere(
        (e) => e.toString() == 'SessionStatus.${data['status']}',
        orElse: () => SessionStatus.active,
      ),
      hoursToAssign: (data['hoursToAssign'] ?? 0.0).toDouble(),
      attendees: List<String>.from(data['attendees'] ?? []),
      checkInTimes: Map<String, DateTime>.from(
        (data['checkInTimes'] as Map<String, dynamic>? ?? {}).map(
          (key, value) => MapEntry(key, (value as Timestamp).toDate()),
        ),
      ),
      attendanceMethods: Map<String, AttendanceMethod>.from(
        (data['attendanceMethods'] as Map<String, dynamic>? ?? {}).map(
          (key, value) => MapEntry(
            key, 
            AttendanceMethod.values.firstWhere(
              (e) => e.toString() == 'AttendanceMethod.$value',
              orElse: () => AttendanceMethod.qrScan,
            ),
          ),
        ),
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null 
          ? (data['updatedAt'] as Timestamp).toDate() 
          : null,
    );
  }

  // Convertir a Map para Firestore
  Map<String, dynamic> toMap() {
    return {
      'eventId': eventId,
      'subEventId': subEventId,
      'coordinatorId': coordinatorId,
      'sessionDate': Timestamp.fromDate(sessionDate),
      'startTime': startTime != null ? Timestamp.fromDate(startTime!) : null,
      'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
      'status': status.toString().split('.').last,
      'hoursToAssign': hoursToAssign,
      'attendees': attendees,
      'checkInTimes': checkInTimes.map(
        (key, value) => MapEntry(key, Timestamp.fromDate(value)),
      ),
      'attendanceMethods': attendanceMethods.map(
        (key, value) => MapEntry(key, value.toString().split('.').last),
      ),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  // Método para agregar un asistente
  AttendanceSessionModel addAttendee(String userId, AttendanceMethod method) {
    final newAttendees = List<String>.from(attendees);
    final newCheckInTimes = Map<String, DateTime>.from(checkInTimes);
    final newMethods = Map<String, AttendanceMethod>.from(attendanceMethods);
    
    if (!newAttendees.contains(userId)) {
      newAttendees.add(userId);
      newCheckInTimes[userId] = DateTime.now();
      newMethods[userId] = method;
    }
    
    return AttendanceSessionModel(
      sessionId: sessionId,
      eventId: eventId,
      subEventId: subEventId,
      coordinatorId: coordinatorId,
      sessionDate: sessionDate,
      startTime: startTime,
      endTime: endTime,
      status: status,
      hoursToAssign: hoursToAssign,
      attendees: newAttendees,
      checkInTimes: newCheckInTimes,
      attendanceMethods: newMethods,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  // Método para cerrar la sesión
  AttendanceSessionModel closeSession() {
    return AttendanceSessionModel(
      sessionId: sessionId,
      eventId: eventId,
      subEventId: subEventId,
      coordinatorId: coordinatorId,
      sessionDate: sessionDate,
      startTime: startTime,
      endTime: DateTime.now(),
      status: SessionStatus.closed,
      hoursToAssign: hoursToAssign,
      attendees: attendees,
      checkInTimes: checkInTimes,
      attendanceMethods: attendanceMethods,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  // Verificar si un usuario ya está registrado en la sesión
  bool isUserRegistered(String userId) {
    return attendees.contains(userId);
  }

  // Obtener el número total de asistentes
  int get totalAttendees => attendees.length;

  // Verificar si la sesión está activa
  bool get isActive => status == SessionStatus.active;

  // Verificar si la sesión está cerrada
  bool get isClosed => status == SessionStatus.closed;
}