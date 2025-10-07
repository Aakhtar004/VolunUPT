class EventEntity {
  final String id;
  final String title;
  final String description;
  final DateTime startDate;
  final int capacity;
  final int inscriptionCount;
  final String status;

  const EventEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.startDate,
    required this.capacity,
    required this.inscriptionCount,
    required this.status,
  });

  EventEntity copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? startDate,
    int? capacity,
    int? inscriptionCount,
    String? status,
  }) {
    return EventEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      capacity: capacity ?? this.capacity,
      inscriptionCount: inscriptionCount ?? this.inscriptionCount,
      status: status ?? this.status,
    );
  }

  bool get hasAvailableSpots => inscriptionCount < capacity;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'startDate': startDate.millisecondsSinceEpoch,
      'capacity': capacity,
      'inscriptionCount': inscriptionCount,
      'status': status,
    };
  }

  factory EventEntity.fromMap(Map<String, dynamic> map) {
    return EventEntity(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      startDate: DateTime.fromMillisecondsSinceEpoch(map['startDate'] ?? 0),
      capacity: map['capacity'] ?? 0,
      inscriptionCount: map['inscriptionCount'] ?? 0,
      status: map['status'] ?? '',
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EventEntity &&
        other.id == id &&
        other.title == title &&
        other.description == description &&
        other.startDate == startDate &&
        other.capacity == capacity &&
        other.inscriptionCount == inscriptionCount &&
        other.status == status;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        title.hashCode ^
        description.hashCode ^
        startDate.hashCode ^
        capacity.hashCode ^
        inscriptionCount.hashCode ^
        status.hashCode;
  }
}