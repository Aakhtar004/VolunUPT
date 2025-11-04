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
    return UserModel(
      uid: snap.id,
      email: snapshot['email'],
      displayName: snapshot['displayName'],
      photoURL: snapshot['photoURL'],
      role: UserRole.values.firstWhere(
        (e) => e.toString() == 'UserRole.${snapshot['role']}',
        orElse: () => UserRole.estudiante,
      ),
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