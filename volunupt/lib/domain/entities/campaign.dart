class Campaign {
  final String id;
  final String title;
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  final String status;
  final String coordinatorId;
  final List<String> participantIds;

  const Campaign({
    required this.id,
    required this.title,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.coordinatorId,
    required this.participantIds,
  });

  Campaign copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
    String? coordinatorId,
    List<String>? participantIds,
  }) {
    return Campaign(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      coordinatorId: coordinatorId ?? this.coordinatorId,
      participantIds: participantIds ?? this.participantIds,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Campaign &&
        other.id == id &&
        other.title == title &&
        other.description == description &&
        other.startDate == startDate &&
        other.endDate == endDate &&
        other.status == status &&
        other.coordinatorId == coordinatorId &&
        other.participantIds == participantIds;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        title.hashCode ^
        description.hashCode ^
        startDate.hashCode ^
        endDate.hashCode ^
        status.hashCode ^
        coordinatorId.hashCode ^
        participantIds.hashCode;
  }
}