class AttendanceEntity {
  final String id;
  final String userId;
  final String userName;
  final String sessionId;
  final DateTime scannedAt;
  final String recordedByName;

  const AttendanceEntity({
    required this.id,
    required this.userId,
    required this.userName,
    required this.sessionId,
    required this.scannedAt,
    required this.recordedByName,
  });

  AttendanceEntity copyWith({
    String? id,
    String? userId,
    String? userName,
    String? sessionId,
    DateTime? scannedAt,
    String? recordedByName,
  }) {
    return AttendanceEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      sessionId: sessionId ?? this.sessionId,
      scannedAt: scannedAt ?? this.scannedAt,
      recordedByName: recordedByName ?? this.recordedByName,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AttendanceEntity &&
        other.id == id &&
        other.userId == userId &&
        other.userName == userName &&
        other.sessionId == sessionId &&
        other.scannedAt == scannedAt &&
        other.recordedByName == recordedByName;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        userId.hashCode ^
        userName.hashCode ^
        sessionId.hashCode ^
        scannedAt.hashCode ^
        recordedByName.hashCode;
  }
}