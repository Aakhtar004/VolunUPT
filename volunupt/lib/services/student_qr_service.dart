import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

class StudentQRValidationResult {
  final bool isValid;
  final String? userId;
  final String? reason;

  const StudentQRValidationResult({
    required this.isValid,
    this.userId,
    this.reason,
  });
}

class StudentQRService {
  static final _qrCol = FirebaseFirestore.instance.collection('studentQRs');

  // Returns the student's QR data string. Creates one if it doesn't exist or is inactive.
  static Future<String> getOrCreateQrData(String userId) async {
    final doc = await _qrCol.doc(userId).get();
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      final isActive = (data['isActive'] ?? true) == true;
      final qr = data['qrCode'] as String?;
      if (isActive && qr != null && qr.isNotEmpty) {
        return qr;
      }
    }

    // Create new QR
    final signature = _randomHex(16);
    final ts = DateTime.now().millisecondsSinceEpoch;
    final payload = {
      't': 'stu', // type: student
      'u': userId,
      's': signature,
      'g': ts, // generated at epoch ms
    };
    final qrData = jsonEncode(payload);

    await _qrCol.doc(userId).set({
      'userId': userId,
      'qrCode': qrData,
      'signature': signature,
      'generatedAt': FieldValue.serverTimestamp(),
      'isActive': true,
      'lastUsed': null,
      'usageCount': 0,
    }, SetOptions(merge: true));

    return qrData;
  }

  static Future<StudentQRValidationResult> validateScannedData(String qrData) async {
    Map<String, dynamic> payload;
    try {
      payload = jsonDecode(qrData) as Map<String, dynamic>;
    } catch (_) {
      return const StudentQRValidationResult(
        isValid: false,
        reason: 'Formato de QR inválido',
      );
    }

    final type = payload['t'] as String?;
    final userId = payload['u'] as String?;
    final signature = payload['s'] as String?;
    if (type != 'stu' || userId == null || signature == null) {
      return const StudentQRValidationResult(
        isValid: false,
        reason: 'Datos incompletos en el QR',
      );
    }

    final doc = await _qrCol.doc(userId).get();
    if (!doc.exists) {
      return const StudentQRValidationResult(
        isValid: false,
        reason: 'QR no registrado',
      );
    }

    final data = doc.data() as Map<String, dynamic>;
    final isActive = (data['isActive'] ?? true) == true;
    final storedSignature = data['signature'] as String?;
    final storedQr = data['qrCode'] as String?;

    if (!isActive) {
      return const StudentQRValidationResult(
        isValid: false,
        reason: 'QR inactivo',
      );
    }

    // Match signature or the exact QR payload to prevent trivial forgery
    if (storedSignature != signature && storedQr != qrData) {
      return const StudentQRValidationResult(
        isValid: false,
        reason: 'QR no coincide con el registrado',
      );
    }

    return StudentQRValidationResult(isValid: true, userId: userId);
  }

  static Future<void> markQrUsed(String userId) async {
    await _qrCol.doc(userId).update({
      'usageCount': FieldValue.increment(1),
      'lastUsed': FieldValue.serverTimestamp(),
    });
  }

  static String _randomHex(int length) {
    final rand = Random.secure();
    final bytes = List<int>.generate(length, (_) => rand.nextInt(256));
    final buffer = StringBuffer();
    for (final b in bytes) {
      buffer.write(b.toRadixString(16).padLeft(2, '0'));
    }
    return buffer.toString();
  }
}