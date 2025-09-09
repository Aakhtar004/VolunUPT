import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String email;
  final String token;
  final String role; // Nuevo campo

  User({
    required this.id,
    required this.email,
    required this.token,
    required this.role,
  });

  @override
  List<Object?> get props => [id, email, token, role];
}
