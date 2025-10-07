class UserProfileEntity {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? photoUrl;
  final String? phone;
  final String? studentCode;
  final String? career;
  final int semester;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool biometricEnabled;
  final bool notificationsEnabled;

  const UserProfileEntity({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.photoUrl,
    this.phone,
    this.studentCode,
    this.career,
    this.semester = 1,
    required this.createdAt,
    required this.updatedAt,
    this.biometricEnabled = false,
    this.notificationsEnabled = true,
  });

  UserProfileEntity copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    String? photoUrl,
    String? phone,
    String? studentCode,
    String? career,
    int? semester,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? biometricEnabled,
    bool? notificationsEnabled,
  }) {
    return UserProfileEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      photoUrl: photoUrl ?? this.photoUrl,
      phone: phone ?? this.phone,
      studentCode: studentCode ?? this.studentCode,
      career: career ?? this.career,
      semester: semester ?? this.semester,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserProfileEntity &&
        other.id == id &&
        other.name == name &&
        other.email == email &&
        other.role == role &&
        other.photoUrl == photoUrl &&
        other.phone == phone &&
        other.studentCode == studentCode &&
        other.career == career &&
        other.semester == semester &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.biometricEnabled == biometricEnabled &&
        other.notificationsEnabled == notificationsEnabled;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      email,
      role,
      photoUrl,
      phone,
      studentCode,
      career,
      semester,
      createdAt,
      updatedAt,
      biometricEnabled,
      notificationsEnabled,
    );
  }
}