class UserEntity {
  final String id;
  final String name;
  final String email;
  final String role;

  const UserEntity({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });

  UserEntity copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
  }) {
    return UserEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserEntity &&
        other.id == id &&
        other.name == name &&
        other.email == email &&
        other.role == role;
  }

  @override
  int get hashCode {
    return id.hashCode ^ name.hashCode ^ email.hashCode ^ role.hashCode;
  }
}