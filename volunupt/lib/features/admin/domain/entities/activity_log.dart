import 'package:cloud_firestore/cloud_firestore.dart';
class ActivityLog {
  final String id;
  final String type;
  final String description;
  final String userId;
  final String? userName;
  final String? targetId;
  final String? targetType;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;
  final String severity;

  const ActivityLog({
    required this.id,
    required this.type,
    required this.description,
    required this.userId,
    this.userName,
    this.targetId,
    this.targetType,
    required this.timestamp,
    required this.metadata,
    required this.severity,
  });

  factory ActivityLog.fromMap(Map<String, dynamic> map) {
    return ActivityLog(
      id: map['id'] ?? '',
      type: map['type'] ?? '',
      description: map['description'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'],
      targetId: map['targetId'],
      targetType: map['targetType'],
      timestamp: _parseDate(map['timestamp']),
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
      severity: map['severity'] ?? 'info',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'description': description,
      'userId': userId,
      'userName': userName,
      'targetId': targetId,
      'targetType': targetType,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
      'severity': severity,
    };
  }

  ActivityLog copyWith({
    String? id,
    String? type,
    String? description,
    String? userId,
    String? userName,
    String? targetId,
    String? targetType,
    DateTime? timestamp,
    Map<String, dynamic>? metadata,
    String? severity,
  }) {
    return ActivityLog(
      id: id ?? this.id,
      type: type ?? this.type,
      description: description ?? this.description,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      targetId: targetId ?? this.targetId,
      targetType: targetType ?? this.targetType,
      timestamp: timestamp ?? this.timestamp,
      metadata: metadata ?? this.metadata,
      severity: severity ?? this.severity,
    );
  }
}

enum ActivityType {
  userRegistration('user_registration', 'Registro de usuario'),
  userLogin('user_login', 'Inicio de sesión'),
  userLogout('user_logout', 'Cierre de sesión'),
  eventCreation('event_creation', 'Creación de evento'),
  eventUpdate('event_update', 'Actualización de evento'),
  eventDeletion('event_deletion', 'Eliminación de evento'),
  inscription('inscription', 'Inscripción a evento'),
  inscriptionCancellation('inscription_cancellation', 'Cancelación de inscripción'),
  attendance('attendance', 'Registro de asistencia'),
  roleChange('role_change', 'Cambio de rol'),
  systemError('system_error', 'Error del sistema'),
  dataExport('data_export', 'Exportación de datos'),
  configurationChange('configuration_change', 'Cambio de configuración');

  const ActivityType(this.value, this.displayName);

  final String value;
  final String displayName;

  static ActivityType fromValue(String value) {
    return ActivityType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => ActivityType.systemError,
    );
  }
}

enum ActivitySeverity {
  info('info', 'Información'),
  warning('warning', 'Advertencia'),
  error('error', 'Error'),
  critical('critical', 'Crítico');

  const ActivitySeverity(this.value, this.displayName);

  final String value;
  final String displayName;

  static ActivitySeverity fromValue(String value) {
    return ActivitySeverity.values.firstWhere(
      (severity) => severity.value == value,
      orElse: () => ActivitySeverity.info,
    );
  }
}

DateTime _parseDate(dynamic value) {
  if (value == null) return DateTime.now();
  if (value is DateTime) return value;
  if (value is Timestamp) return value.toDate();
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  if (value is String) {
    return DateTime.tryParse(value) ?? DateTime.now();
  }
  return DateTime.now();
}