import 'package:cloud_firestore/cloud_firestore.dart';
import 'enums.dart';

class AttendanceRecordModel {
  final String recordId;
  final String userId;
  final String subEventId;
  final String baseEventId;
  final String sessionId; // ID de la sesión de asistencia
  final DateTime checkInTime;
  final AttendanceStatus status;
  final double hoursEarned;
  final AttendanceMethod attendanceMethod; // Método usado para registrar asistencia
  final String? validatedBy; // Nullable for initial check-in
  final DateTime? validatedAt; // Nullable for initial check-in
  final String? coordinatorNotes; // Notas del coordinador (opcional)

  AttendanceRecordModel({
    required this.recordId,
    required this.userId,
    required this.subEventId,
    required this.baseEventId,
    required this.sessionId,
    required this.checkInTime,
    this.status = AttendanceStatus.checkedIn,
    this.hoursEarned = 0.0,
    required this.attendanceMethod,
    this.validatedBy,
    this.validatedAt,
    this.coordinatorNotes,
  });

  factory AttendanceRecordModel.fromSnapshot(DocumentSnapshot snap) {
    var snapshot = snap.data() as Map<String, dynamic>;
    return AttendanceRecordModel(
      recordId: snap.id,
      userId: snapshot['userId'],
      subEventId: snapshot['subEventId'],
      baseEventId: snapshot['baseEventId'],
      sessionId: snapshot['sessionId'] ?? '',
      checkInTime: (snapshot['checkInTime'] as Timestamp).toDate(),
      status: AttendanceStatus.values.firstWhere(
        (e) => e.toString() == 'AttendanceStatus.${snapshot['status']}',
        orElse: () => AttendanceStatus.absent,
      ),
      hoursEarned: (snapshot['hoursEarned'] ?? 0.0).toDouble(),
      attendanceMethod: AttendanceMethod.values.firstWhere(
        (e) => e.toString() == 'AttendanceMethod.${snapshot['attendanceMethod'] ?? 'qrScan'}',
        orElse: () => AttendanceMethod.qrScan,
      ),
      validatedBy: snapshot['validatedBy'],
      validatedAt: snapshot['validatedAt'] != null
          ? (snapshot['validatedAt'] as Timestamp).toDate()
          : null,
      coordinatorNotes: snapshot['coordinatorNotes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'subEventId': subEventId,
      'baseEventId': baseEventId,
      'sessionId': sessionId,
      'checkInTime': Timestamp.fromDate(checkInTime),
      'status': status.toString().split('.').last,
      'hoursEarned': hoursEarned,
      'attendanceMethod': attendanceMethod.toString().split('.').last,
      'validatedBy': validatedBy,
      'validatedAt': validatedAt != null ? Timestamp.fromDate(validatedAt!) : null,
      'coordinatorNotes': coordinatorNotes,
    };
  }

  // Alias para compatibilidad con otros servicios que esperan 'hoursWorked'
  double get hoursWorked => hoursEarned;
}