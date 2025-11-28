import 'package:cloud_firestore/cloud_firestore.dart';
import 'enums.dart';

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String photoURL;
  final UserRole role;
  final double totalHours;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.photoURL,
    required this.role,
    this.totalHours = 0.0,
  });

  factory UserModel.fromSnapshot(DocumentSnapshot snap) {
    var snapshot = snap.data() as Map<String, dynamic>;
    
    // Parsear rol de forma más robusta
    UserRole userRole = UserRole.estudiante;
    final roleString = snapshot['role']?.toString().toLowerCase() ?? '';
    
    try {
      // Intentar parsear directamente desde el string
      if (roleString == 'coordinador') {
        userRole = UserRole.coordinador;
      } else if (roleString == 'administrador') {
        userRole = UserRole.administrador;
      } else if (roleString == 'estudiante') {
        userRole = UserRole.estudiante;
      } else {
        // Fallback: intentar con el método original
        userRole = UserRole.values.firstWhere(
          (e) => e.toString().split('.').last.toLowerCase() == roleString,
          orElse: () => UserRole.estudiante,
        );
      }
    } catch (e) {
      // Si falla, usar estudiante por defecto
      userRole = UserRole.estudiante;
    }
    
    return UserModel(
      uid: snap.id,
      email: snapshot['email'] ?? '',
      displayName: snapshot['displayName'] ?? '',
      photoURL: snapshot['photoURL'] ?? '',
      role: userRole,
      totalHours: (snapshot['totalHours'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'role': role.toString().split('.').last,
      'totalHours': totalHours,
    };
  }
}