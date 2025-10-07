class UserStatsEntity {
  final int completedEvents;
  final int totalHours;
  final int certificates;
  final int activeInscriptions;
  final int attendedEvents;

  const UserStatsEntity({
    required this.completedEvents,
    required this.totalHours,
    required this.certificates,
    required this.activeInscriptions,
    required this.attendedEvents,
  });

  factory UserStatsEntity.fromMap(Map<String, dynamic> map) {
    return UserStatsEntity(
      completedEvents: map['completedEvents'] ?? 0,
      totalHours: map['totalHours'] ?? 0,
      certificates: map['certificates'] ?? 0,
      activeInscriptions: map['activeInscriptions'] ?? 0,
      attendedEvents: map['attendedEvents'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'completedEvents': completedEvents,
      'totalHours': totalHours,
      'certificates': certificates,
      'activeInscriptions': activeInscriptions,
      'attendedEvents': attendedEvents,
    };
  }

  UserStatsEntity copyWith({
    int? completedEvents,
    int? totalHours,
    int? certificates,
    int? activeInscriptions,
    int? attendedEvents,
  }) {
    return UserStatsEntity(
      completedEvents: completedEvents ?? this.completedEvents,
      totalHours: totalHours ?? this.totalHours,
      certificates: certificates ?? this.certificates,
      activeInscriptions: activeInscriptions ?? this.activeInscriptions,
      attendedEvents: attendedEvents ?? this.attendedEvents,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserStatsEntity &&
        other.completedEvents == completedEvents &&
        other.totalHours == totalHours &&
        other.certificates == certificates &&
        other.activeInscriptions == activeInscriptions &&
        other.attendedEvents == attendedEvents;
  }

  @override
  int get hashCode {
    return completedEvents.hashCode ^
        totalHours.hashCode ^
        certificates.hashCode ^
        activeInscriptions.hashCode ^
        attendedEvents.hashCode;
  }
}