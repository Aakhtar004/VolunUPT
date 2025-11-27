import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';

class CertificateService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _certificatesCollection = 'certificates';
  static const String _attendanceRecordsCollection = 'attendanceRecords';
  static const String _eventsCollection = 'events';

  // Obtener certificados de un usuario
  static Stream<List<CertificateModel>> getUserCertificates(String userId) {
    return _firestore
        .collection(_certificatesCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('dateIssued', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CertificateModel.fromSnapshot(doc))
            .toList());
  }

  static Future<int> countAllCertificates() async {
    final q = await _firestore.collection(_certificatesCollection).get();
    return q.docs.length;
  }

  // Obtener certificado por ID
  static Future<CertificateModel?> getCertificateById(String certificateId) async {
    try {
      final doc = await _firestore
          .collection(_certificatesCollection)
          .doc(certificateId)
          .get();
      
      if (doc.exists) {
        return CertificateModel.fromSnapshot(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Error al obtener certificado: $e');
    }
  }

  // Verificar si un usuario puede obtener certificado para un evento
  static Future<bool> canUserGetCertificate(String userId, String eventId) async {
    try {
      // Verificar si ya tiene certificado para este evento
      final existingCertificate = await _firestore
          .collection(_certificatesCollection)
          .where('userId', isEqualTo: userId)
          .where('baseEventId', isEqualTo: eventId)
          .get();

      if (existingCertificate.docs.isNotEmpty) {
        return false; // Ya tiene certificado
      }

      // Obtener información del evento
      final eventDoc = await _firestore
          .collection(_eventsCollection)
          .doc(eventId)
          .get();

      if (!eventDoc.exists) {
        return false;
      }

      final event = EventModel.fromSnapshot(eventDoc);

      // Calcular horas totales del usuario en este evento
      final totalHours = await getUserTotalHoursForEvent(userId, eventId);

      // Verificar si cumple con las horas requeridas
      return totalHours >= event.totalHoursForCertificate;
    } catch (e) {
      throw Exception('Error al verificar elegibilidad para certificado: $e');
    }
  }

  // Obtener total de horas de un usuario para un evento específico
  static Future<double> getUserTotalHoursForEvent(String userId, String eventId) async {
    try {
      final attendanceRecords = await _firestore
          .collection(_attendanceRecordsCollection)
          .where('userId', isEqualTo: userId)
          .where('baseEventId', isEqualTo: eventId)
          .where('status', isEqualTo: AttendanceStatus.validated.toString().split('.').last)
          .get();

      double totalHours = 0.0;
      for (final doc in attendanceRecords.docs) {
        final record = AttendanceRecordModel.fromSnapshot(doc);
        totalHours += record.hoursEarned;
      }

      return totalHours;
    } catch (e) {
      throw Exception('Error al calcular horas totales: $e');
    }
  }

  // Generar certificado para un usuario
  static Future<String> generateCertificate({
    required String userId,
    required String eventId,
    required String userName,
    required String eventTitle,
    required double totalHours,
  }) async {
    try {
      // Verificar elegibilidad
      final canGenerate = await canUserGetCertificate(userId, eventId);
      if (!canGenerate) {
        throw Exception('El usuario no es elegible para este certificado');
      }

      // Crear certificado
      final certificate = CertificateModel(
        certificateId: '', // Se asignará automáticamente
        userId: userId,
        baseEventId: eventId,
        pdfUrl: '', // Se generará después
        dateIssued: DateTime.now(),
        hoursCompleted: totalHours,
      );

      final docRef = await _firestore
          .collection(_certificatesCollection)
          .add(certificate.toMap());

      // TODO: Aquí se llamaría a Cloud Function para generar el PDF
      // Por ahora, solo guardamos la referencia
      await docRef.update({
        'pdfUrl': 'certificates/${docRef.id}.pdf'
      });

      return docRef.id;
    } catch (e) {
      throw Exception('Error al generar certificado: $e');
    }
  }

  // Verificar certificado por código
  static Future<CertificateModel?> verifyCertificate(String verificationCode) async {
    try {
      final query = await _firestore
          .collection(_certificatesCollection)
          .where('verificationCode', isEqualTo: verificationCode)
          .get();

      if (query.docs.isNotEmpty) {
        return CertificateModel.fromSnapshot(query.docs.first);
      }
      return null;
    } catch (e) {
      throw Exception('Error al verificar certificado: $e');
    }
  }

  // Obtener estadísticas de certificados para administradores
  static Future<Map<String, dynamic>> getCertificateStats() async {
    try {
      final certificates = await _firestore
          .collection(_certificatesCollection)
          .get();

      final totalCertificates = certificates.docs.length;
      
      // Agrupar por evento
      final Map<String, int> certificatesByEvent = {};
      for (final doc in certificates.docs) {
        final certificate = CertificateModel.fromSnapshot(doc);
        certificatesByEvent[certificate.baseEventId] = 
            (certificatesByEvent[certificate.baseEventId] ?? 0) + 1;
      }

      // Certificados emitidos en el último mes
      final lastMonth = DateTime.now().subtract(const Duration(days: 30));
      final recentCertificates = certificates.docs.where((doc) {
        final certificate = CertificateModel.fromSnapshot(doc);
        return certificate.dateIssued.isAfter(lastMonth);
      }).length;

      return {
        'totalCertificates': totalCertificates,
        'certificatesByEvent': certificatesByEvent,
        'recentCertificates': recentCertificates,
      };
    } catch (e) {
      throw Exception('Error al obtener estadísticas de certificados: $e');
    }
  }

  // Obtener eventos elegibles para certificado de un usuario
  static Future<List<Map<String, dynamic>>> getEligibleEventsForUser(String userId) async {
    try {
      final List<Map<String, dynamic>> eligibleEvents = [];

      // Obtener todos los eventos donde el usuario tiene registros de asistencia
      final attendanceRecords = await _firestore
          .collection(_attendanceRecordsCollection)
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: AttendanceStatus.validated.toString().split('.').last)
          .get();

      // Agrupar por evento base
      final Map<String, double> hoursByEvent = {};
      for (final doc in attendanceRecords.docs) {
        final record = AttendanceRecordModel.fromSnapshot(doc);
        hoursByEvent[record.baseEventId] = 
            (hoursByEvent[record.baseEventId] ?? 0.0) + record.hoursEarned;
      }

      // Verificar cada evento
      for (final eventId in hoursByEvent.keys) {
        final eventDoc = await _firestore
            .collection(_eventsCollection)
            .doc(eventId)
            .get();

        if (eventDoc.exists) {
          final event = EventModel.fromSnapshot(eventDoc);
          final userHours = hoursByEvent[eventId]!;

          // Verificar si ya tiene certificado
          final existingCertificate = await _firestore
              .collection(_certificatesCollection)
              .where('userId', isEqualTo: userId)
              .where('baseEventId', isEqualTo: eventId)
              .get();

          final bool isEligible = userHours >= event.totalHoursForCertificate;
          final bool hasCertificate = existingCertificate.docs.isNotEmpty;

          eligibleEvents.add({
            'event': event,
            'userHours': userHours,
            'requiredHours': event.totalHoursForCertificate,
            'isEligible': isEligible,
            'hasCertificate': hasCertificate,
            'canGenerate': isEligible && !hasCertificate,
          });
        }
      }

      return eligibleEvents;
    } catch (e) {
      throw Exception('Error al obtener eventos elegibles: $e');
    }
  }

  // Eliminar certificado (solo administradores)
  static Future<void> deleteCertificate(String certificateId) async {
    try {
      await _firestore
          .collection(_certificatesCollection)
          .doc(certificateId)
          .delete();
    } catch (e) {
      throw Exception('Error al eliminar certificado: $e');
    }
  }

  // Obtener todos los certificados (solo administradores)
  static Stream<List<CertificateModel>> getAllCertificates() {
    return _firestore
        .collection(_certificatesCollection)
        .orderBy('dateIssued', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CertificateModel.fromSnapshot(doc))
            .toList());
  }
}