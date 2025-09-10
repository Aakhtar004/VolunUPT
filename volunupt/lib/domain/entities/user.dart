import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String email;
  final String token;
  final String role; // 'Estudiante' o 'Coordinador'
  final String fullName;

  const User({
    required this.id,
    required this.email,
    required this.token,
    required this.role,
    required this.fullName,
  });

  @override
  List<Object?> get props => [id, email, token, role, fullName];
}
