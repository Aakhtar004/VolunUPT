import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class StudentQRModel {
  final String userId;
  final String qrCode; // Código QR único del estudiante
  final DateTime generatedAt;
  final bool isActive;
  final String signature; // Hash de seguridad
  final DateTime? lastUsed;
  final int usageCount; // Contador de usos

  StudentQRModel({
    required this.userId,
    required this.qrCode,
    required this.generatedAt,
    required this.isActive,
    required this.signature,
    this.lastUsed,
    required this.usageCount,
  });

  // Crear desde DocumentSnapshot de Firestore
  factory StudentQRModel.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;
    
    return StudentQRModel(
      userId: snapshot.id,
      qrCode: data['qrCode'] ?? '',
      generatedAt: (data['generatedAt'] as Timestamp).toDate(),
      isActive: data['isActive'] ?? true,
      signature: data['signature'] ?? '',
      lastUsed: data['lastUsed'] != null 
          ? (data['lastUsed'] as Timestamp).toDate() 
          : null,
      usageCount: data['usageCount'] ?? 0,
    );
  }

  // Convertir a Map para Firestore
  Map<String, dynamic> toMap() {
    return {
      'qrCode': qrCode,
      'generatedAt': Timestamp.fromDate(generatedAt),
      'isActive': isActive,
      'signature': signature,
      'lastUsed': lastUsed != null ? Timestamp.fromDate(lastUsed!) : null,
      'usageCount': usageCount,
    };
  }

  // Generar un nuevo QR para el estudiante
  static StudentQRModel generateForStudent(String userId) {
    final timestamp = DateTime.now();
    final qrData = {
      'userId': userId,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'type': 'student_qr'
    };
    
    // Crear el código QR como JSON
    final qrCode = jsonEncode(qrData);
    
    // Generar signature de seguridad
    final signature = _generateSignature(userId, timestamp);
    
    return StudentQRModel(
      userId: userId,
      qrCode: qrCode,
      generatedAt: timestamp,
      isActive: true,
      signature: signature,
      usageCount: 0,
    );
  }

  // Generar signature de seguridad
  static String _generateSignature(String userId, DateTime timestamp) {
    final data = '$userId:${timestamp.millisecondsSinceEpoch}:volunupt_secret';
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Validar la integridad del QR
  bool validateQR() {
    try {
      final qrData = jsonDecode(qrCode);
      final expectedSignature = _generateSignature(
        qrData['userId'], 
        DateTime.fromMillisecondsSinceEpoch(qrData['timestamp'])
      );
      return signature == expectedSignature && isActive;
    } catch (e) {
      return false;
    }
  }

  // Extraer datos del QR
  Map<String, dynamic>? getQRData() {
    try {
      return jsonDecode(qrCode);
    } catch (e) {
      return null;
    }
  }

  // Marcar como usado
  StudentQRModel markAsUsed() {
    return StudentQRModel(
      userId: userId,
      qrCode: qrCode,
      generatedAt: generatedAt,
      isActive: isActive,
      signature: signature,
      lastUsed: DateTime.now(),
      usageCount: usageCount + 1,
    );
  }

  // Desactivar el QR
  StudentQRModel deactivate() {
    return StudentQRModel(
      userId: userId,
      qrCode: qrCode,
      generatedAt: generatedAt,
      isActive: false,
      signature: signature,
      lastUsed: lastUsed,
      usageCount: usageCount,
    );
  }

  // Verificar si el QR ha expirado (opcional: 24 horas de validez)
  bool get isExpired {
    final expirationTime = generatedAt.add(const Duration(hours: 24));
    return DateTime.now().isAfter(expirationTime);
  }

  // Verificar si el QR es válido para uso
  bool get isValidForUse {
    return isActive && !isExpired && validateQR();
  }

  // Obtener información de uso
  String get usageInfo {
    if (lastUsed != null) {
      return 'Usado $usageCount veces. Último uso: ${lastUsed!.day}/${lastUsed!.month}/${lastUsed!.year}';
    }
    return 'Nunca usado';
  }
}