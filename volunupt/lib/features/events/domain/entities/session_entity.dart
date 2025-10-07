class SessionEntity {
  final String id;
  final String title;
  final DateTime sessionTime;

  const SessionEntity({
    required this.id,
    required this.title,
    required this.sessionTime,
  });

  SessionEntity copyWith({
    String? id,
    String? title,
    DateTime? sessionTime,
  }) {
    return SessionEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      sessionTime: sessionTime ?? this.sessionTime,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SessionEntity &&
        other.id == id &&
        other.title == title &&
        other.sessionTime == sessionTime;
  }

  @override
  int get hashCode {
    return id.hashCode ^ title.hashCode ^ sessionTime.hashCode;
  }
}