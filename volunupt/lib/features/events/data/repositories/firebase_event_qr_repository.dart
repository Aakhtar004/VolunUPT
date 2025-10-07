import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/event_qr_entity.dart';
import '../../domain/repositories/event_qr_repository.dart';

class FirebaseEventQrRepository implements EventQrRepository {
  final FirebaseFirestore _firestore;
  final Uuid _uuid = const Uuid();

  FirebaseEventQrRepository(this._firestore);

  @override
  Future<EventQrEntity> generateQrCode(String eventId, String userId) async {
    try {
      final qrCode = _uuid.v4();
      final now = DateTime.now();
      final expiresAt = now.add(const Duration(hours: 24));
      
      final qrEntity = EventQrEntity(
        id: _uuid.v4(),
        eventId: eventId,
        userId: userId,
        qrCode: qrCode,
        generatedAt: now,
        expiresAt: expiresAt,
      );

      await _firestore.collection('event_qr_codes').doc(qrEntity.id).set({
        'eventId': qrEntity.eventId,
        'userId': qrEntity.userId,
        'qrCode': qrEntity.qrCode,
        'generatedAt': Timestamp.fromDate(qrEntity.generatedAt),
        'expiresAt': Timestamp.fromDate(qrEntity.expiresAt),
        'isUsed': qrEntity.isUsed,
        'usedAt': qrEntity.usedAt != null ? Timestamp.fromDate(qrEntity.usedAt!) : null,
        'scannedBy': qrEntity.scannedBy,
      });

      return qrEntity;
    } catch (e) {
      throw Exception('Error al generar código QR: $e');
    }
  }

  @override
  Future<EventQrEntity?> getQrCode(String eventId, String userId) async {
    try {
      final query = await _firestore
          .collection('event_qr_codes')
          .where('eventId', isEqualTo: eventId)
          .where('userId', isEqualTo: userId)
          .orderBy('generatedAt', descending: true)
          .limit(1)
          .get();

      if (query.docs.isEmpty) return null;

      final doc = query.docs.first;
      final data = doc.data();

      return EventQrEntity(
        id: doc.id,
        eventId: data['eventId'],
        userId: data['userId'],
        qrCode: data['qrCode'],
        generatedAt: (data['generatedAt'] as Timestamp).toDate(),
        expiresAt: (data['expiresAt'] as Timestamp).toDate(),
        isUsed: data['isUsed'] ?? false,
        usedAt: data['usedAt'] != null ? (data['usedAt'] as Timestamp).toDate() : null,
        scannedBy: data['scannedBy'],
      );
    } catch (e) {
      throw Exception('Error al obtener código QR: $e');
    }
  }

  @override
  Future<EventQrEntity?> validateQrCode(String qrCode) async {
    try {
      final query = await _firestore
          .collection('event_qr_codes')
          .where('qrCode', isEqualTo: qrCode)
          .limit(1)
          .get();

      if (query.docs.isEmpty) return null;

      final doc = query.docs.first;
      final data = doc.data();

      return EventQrEntity(
        id: doc.id,
        eventId: data['eventId'],
        userId: data['userId'],
        qrCode: data['qrCode'],
        generatedAt: (data['generatedAt'] as Timestamp).toDate(),
        expiresAt: (data['expiresAt'] as Timestamp).toDate(),
        isUsed: data['isUsed'] ?? false,
        usedAt: data['usedAt'] != null ? (data['usedAt'] as Timestamp).toDate() : null,
        scannedBy: data['scannedBy'],
      );
    } catch (e) {
      throw Exception('Error al validar código QR: $e');
    }
  }

  @override
  Future<void> markQrAsUsed(String qrCode, String scannedBy) async {
    try {
      final query = await _firestore
          .collection('event_qr_codes')
          .where('qrCode', isEqualTo: qrCode)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        await query.docs.first.reference.update({
          'isUsed': true,
          'usedAt': FieldValue.serverTimestamp(),
          'scannedBy': scannedBy,
        });
      }
    } catch (e) {
      throw Exception('Error al marcar código QR como usado: $e');
    }
  }

  @override
  Future<List<EventQrEntity>> getEventQrCodes(String eventId) async {
    try {
      final query = await _firestore
          .collection('event_qr_codes')
          .where('eventId', isEqualTo: eventId)
          .orderBy('generatedAt', descending: true)
          .get();

      return query.docs.map((doc) {
        final data = doc.data();
        return EventQrEntity(
          id: doc.id,
          eventId: data['eventId'],
          userId: data['userId'],
          qrCode: data['qrCode'],
          generatedAt: (data['generatedAt'] as Timestamp).toDate(),
          expiresAt: (data['expiresAt'] as Timestamp).toDate(),
          isUsed: data['isUsed'] ?? false,
          usedAt: data['usedAt'] != null ? (data['usedAt'] as Timestamp).toDate() : null,
          scannedBy: data['scannedBy'],
        );
      }).toList();
    } catch (e) {
      throw Exception('Error al obtener códigos QR del evento: $e');
    }
  }

  @override
  Future<List<EventQrEntity>> getUserQrCodes(String userId) async {
    try {
      final query = await _firestore
          .collection('event_qr_codes')
          .where('userId', isEqualTo: userId)
          .orderBy('generatedAt', descending: true)
          .get();

      return query.docs.map((doc) {
        final data = doc.data();
        return EventQrEntity(
          id: doc.id,
          eventId: data['eventId'],
          userId: data['userId'],
          qrCode: data['qrCode'],
          generatedAt: (data['generatedAt'] as Timestamp).toDate(),
          expiresAt: (data['expiresAt'] as Timestamp).toDate(),
          isUsed: data['isUsed'] ?? false,
          usedAt: data['usedAt'] != null ? (data['usedAt'] as Timestamp).toDate() : null,
          scannedBy: data['scannedBy'],
        );
      }).toList();
    } catch (e) {
      throw Exception('Error al obtener códigos QR del usuario: $e');
    }
  }
}