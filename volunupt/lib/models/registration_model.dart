import 'package:cloud_firestore/cloud_firestore.dart';

class RegistrationModel {
  final String registrationId;
  final String userId;
  final String subEventId;
  final String baseEventId;
  final DateTime registeredAt;

  RegistrationModel({
    required this.registrationId,
    required this.userId,
    required this.subEventId,
    required this.baseEventId,
    required this.registeredAt,
  });

  // Crear desde un documento de Firestore
  factory RegistrationModel.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;
    return RegistrationModel(
      registrationId: snapshot.id,
      userId: data['userId'] ?? '',
      subEventId: data['subEventId'] ?? '',
      baseEventId: data['baseEventId'] ?? '',
      registeredAt: (data['registeredAt'] as Timestamp).toDate(),
    );
  }

  // Convertir a Map para guardar en Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'subEventId': subEventId,
      'baseEventId': baseEventId,
      'registeredAt': Timestamp.fromDate(registeredAt),
    };
  }
}