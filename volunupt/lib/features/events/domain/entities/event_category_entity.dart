class EventCategoryEntity {
  final String id;
  final String name;
  final String description;
  final bool isActive;

  const EventCategoryEntity({
    required this.id,
    required this.name,
    required this.description,
    required this.isActive,
  });

  factory EventCategoryEntity.fromMap(Map<String, dynamic> map) {
    return EventCategoryEntity(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      isActive: map['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'isActive': isActive,
    };
  }

  EventCategoryEntity copyWith({
    String? id,
    String? name,
    String? description,
    bool? isActive,
  }) {
    return EventCategoryEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EventCategoryEntity &&
        other.id == id &&
        other.name == name &&
        other.description == description &&
        other.isActive == isActive;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        description.hashCode ^
        isActive.hashCode;
  }
}