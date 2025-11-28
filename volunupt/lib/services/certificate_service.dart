import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';
import 'event_service.dart';

class CertificateService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _certificatesCollection = 'certificates';
  static const String _attendanceRecordsCollection = 'attendanceRecords';
  static const String _eventsCollection = 'events';
  
  // Generar certificado vía API y guardar en Firestore
  static Future<File> generateCertificate({
    required String userId,
    required String userName,
    required String school,
    required String eventId,
    required String eventTitle,
    required double hours,
    required String verificationCode,
  }) async {
    try {
      // 1. Llamar a la API
      final url = Uri.parse('http://38.250.161.53:8000/generar-certificado');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "nombre_completo": userName,
          "escuela": school,
          "nombre_campana": eventTitle,
          "horas": hours,
          "codigo_verificacion": verificationCode,
        }),
      );

      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        final dir = await getApplicationDocumentsDirectory();
        final fileName = 'certificado_${verificationCode}_${DateTime.now().millisecondsSinceEpoch}.pdf';
        final file = File('${dir.path}/$fileName');
        await file.writeAsBytes(bytes);

        // 2. Guardar registro en Firestore
        final certificate = CertificateModel(
          certificateId: '', // Se genera auto
          userId: userId,
          baseEventId: eventId,
          eventTitle: eventTitle,
          dateIssued: DateTime.now(),
          pdfUrl: file.path, 
          validationCode: verificationCode,
          hoursCompleted: hours,
        );

        await _firestore.collection(_certificatesCollection).add(certificate.toMap());

        return file;
      } else {
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al generar certificado: $e');
    }
  }



  // Obtener eventos elegibles para certificado (Status finalizado y > 85% asistencia)
  static Future<List<EventModel>> getEligibleEventsForCertificate(String userId) async {
    try {
      // 1. Obtener eventos donde el usuario está inscrito
      final registrationsSnapshot = await _firestore
          .collection('registrations')
          .where('userId', isEqualTo: userId)
          .get();

      final eventIds = registrationsSnapshot.docs
          .map((doc) => doc.data()['baseEventId'] as String)
          .toSet()
          .toList();

      List<EventModel> eligibleEvents = [];

      for (final eventId in eventIds) {
        // 2. Obtener detalles del evento
        final eventDoc = await _firestore.collection(_eventsCollection).doc(eventId).get();
        if (!eventDoc.exists) continue;
        
        final event = EventModel.fromSnapshot(eventDoc);

        // 3. Verificar estado finalizado
        if (event.status != EventStatus.completado) continue;
        
        final existingCert = await _firestore
            .collection(_certificatesCollection)
            .where('userId', isEqualTo: userId)
            .where('baseEventId', isEqualTo: eventId)
            .get();
            
        if (existingCert.docs.isNotEmpty) continue; // Ya lo generó

        // 5. Calcular porcentaje de asistencia
        final totalEventHours = await EventService.calculateTotalHours(eventId);
        if (totalEventHours == 0) continue;

        final userHours = await getUserTotalHoursForEvent(userId, eventId);
        final percentage = (userHours / totalEventHours) * 100;

        if (percentage > 85) {
          eligibleEvents.add(event);
        }
      }

      return eligibleEvents;
    } catch (e) {
      throw Exception('Error al buscar eventos elegibles: $e');
    }
  }

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

  // Verificar si un usuario YA TIENE certificado (helper existente)
  static Future<bool> hasCertificate(String userId, String eventId) async {
      final existingCertificate = await _firestore
          .collection(_certificatesCollection)
          .where('userId', isEqualTo: userId)
          .where('baseEventId', isEqualTo: eventId)
          .get();
      return existingCertificate.docs.isNotEmpty;
  }

  // Verificar si un usuario puede obtener certificado (Lógica antigua, mantenida por compatibilidad si se usa en otro lado)
  static Future<bool> canUserGetCertificate(String userId, String eventId) async {
    try {
      if (await hasCertificate(userId, eventId)) return false;

      final eventDoc = await _firestore.collection(_eventsCollection).doc(eventId).get();
      if (!eventDoc.exists) return false;

      final totalHours = await getUserTotalHoursForEvent(userId, eventId);
      final requiredHours = await EventService.calculateTotalHours(eventId);

      return totalHours >= requiredHours; 
    } catch (e) {
      throw Exception('Error al verificar elegibilidad: $e');
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

          // Calcular horas requeridas dinámicamente
          final requiredHours = await EventService.calculateTotalHours(eventId);

          // Verificar si ya tiene certificado
          final existingCertificate = await _firestore
              .collection(_certificatesCollection)
              .where('userId', isEqualTo: userId)
              .where('baseEventId', isEqualTo: eventId)
              .get();

          final bool isEligible = userHours >= requiredHours;
          final bool hasCertificate = existingCertificate.docs.isNotEmpty;

          eligibleEvents.add({
            'event': event,
            'userHours': userHours,
            'requiredHours': requiredHours,
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