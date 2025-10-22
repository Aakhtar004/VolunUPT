class EventEntity {
  final String id;
  final String title;
  final String description;
  final DateTime startDate;
  final DateTime? endDate;
  final String? location;
  final int capacity;
  final int inscriptionCount;
  final String status;
  final int volunteerHours;
  final String? categoryId;
  final String? imageUrl;

  const EventEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.startDate,
    this.endDate,
    this.location,
    required this.capacity,
    required this.inscriptionCount,
    required this.status,
    this.volunteerHours = 0,
    this.categoryId,
    this.imageUrl,
  });

  EventEntity copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    String? location,
    int? capacity,
    int? inscriptionCount,
    String? status,
    int? volunteerHours,
    String? categoryId,
    String? imageUrl,
  }) {
    return EventEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      location: location ?? this.location,
      capacity: capacity ?? this.capacity,
      inscriptionCount: inscriptionCount ?? this.inscriptionCount,
      status: status ?? this.status,
      volunteerHours: volunteerHours ?? this.volunteerHours,
      categoryId: categoryId ?? this.categoryId,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  bool get hasAvailableSpots => inscriptionCount < capacity;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'startDate': startDate.millisecondsSinceEpoch,
      'endDate': endDate?.millisecondsSinceEpoch,
      'location': location,
      'capacity': capacity,
      'inscriptionCount': inscriptionCount,
      'status': status,
      'volunteerHours': volunteerHours,
      'categoryId': categoryId,
      'imageUrl': imageUrl,
    };
  }

  factory EventEntity.fromMap(Map<String, dynamic> map) {
    return EventEntity(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      startDate: DateTime.fromMillisecondsSinceEpoch(map['startDate'] ?? 0),
      endDate: map['endDate'] != null ? DateTime.fromMillisecondsSinceEpoch(map['endDate']) : null,
      location: map['location'],
      capacity: map['capacity'] ?? 0,
      inscriptionCount: map['inscriptionCount'] ?? 0,
      status: map['status'] ?? '',
      volunteerHours: map['volunteerHours'] ?? 0,
      categoryId: map['categoryId'],
      imageUrl: map['imageUrl'],
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
        other.endDate == endDate &&
        other.location == location &&
        other.capacity == capacity &&
        other.inscriptionCount == inscriptionCount &&
        other.status == status &&
        other.volunteerHours == volunteerHours &&
        other.categoryId == categoryId &&
        other.imageUrl == imageUrl;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        title.hashCode ^
        description.hashCode ^
        startDate.hashCode ^
        endDate.hashCode ^
        location.hashCode ^
        capacity.hashCode ^
        inscriptionCount.hashCode ^
        status.hashCode ^
        volunteerHours.hashCode ^
        categoryId.hashCode ^
        imageUrl.hashCode;
  }
}