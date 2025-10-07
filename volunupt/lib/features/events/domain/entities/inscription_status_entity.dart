class InscriptionStatusEntity {
  final String id;
  final String name;
  final String description;
  final bool isActive;

  const InscriptionStatusEntity({
    required this.id,
    required this.name,
    required this.description,
    required this.isActive,
  });

  factory InscriptionStatusEntity.fromMap(Map<String, dynamic> map) {
    return InscriptionStatusEntity(
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

  static List<InscriptionStatusEntity> getDefaultStatuses() {
    return [
      const InscriptionStatusEntity(
        id: 'all',
        name: 'Todas',
        description: 'Todas las inscripciones',
        isActive: true,
      ),
      const InscriptionStatusEntity(
        id: 'confirmed',
        name: 'Confirmadas',
        description: 'Inscripciones confirmadas',
        isActive: true,
      ),
      const InscriptionStatusEntity(
        id: 'waiting',
        name: 'En Espera',
        description: 'En lista de espera',
        isActive: true,
      ),
      const InscriptionStatusEntity(
        id: 'cancelled',
        name: 'Canceladas',
        description: 'Inscripciones canceladas',
        isActive: true,
      ),
    ];
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is InscriptionStatusEntity &&
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