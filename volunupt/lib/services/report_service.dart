import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';
import 'event_service.dart';

class ReportService {
  static const String _baseUrl = 'http://38.250.161.53:8000';
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Generar reporte de asistencia para un evento.
  /// Retorna el PDF como List de int (bytes).
  static Future<List<int>> generateAttendanceReport({
    required String eventId,
  }) async {
    try {
      // Obtener el evento
      final event = await EventService.getEventById(eventId);
      if (event == null) {
        throw Exception('El evento no existe');
      }

      // Obtener todas las actividades del evento
      final subEventsQuery = await _firestore
          .collection('subEvents')
          .where('baseEventId', isEqualTo: eventId)
          .get();

      final subEvents = subEventsQuery.docs
          .map((doc) => SubEventModel.fromSnapshot(doc))
          .toList();
      
      // Ordenar actividades por fecha
      subEvents.sort((a, b) => a.date.compareTo(b.date));

      // Mapear actividades al formato requerido por la API
      final actividades = subEvents.asMap().entries.map((entry) {
        return {
          'id': entry.key + 1, // IDs empezando desde 1
          'nombre': entry.value.title,
        };
      }).toList();

      // Obtener todas las inscripciones al evento (tanto al programa como a actividades específicas)
      final registrationsQuery = await _firestore
          .collection('registrations')
          .where('baseEventId', isEqualTo: eventId)
          .get();

      // Agrupar inscripciones por usuario
      final Map<String, Set<String>> userSubEvents = {}; // userId -> Set<subEventId>
      final Set<String> userIds = {};

      for (final regDoc in registrationsQuery.docs) {
        final regData = regDoc.data();
        final userId = regData['userId'] as String;
        final subEventId = regData['subEventId'] as String? ?? '';

        userIds.add(userId);

        // Si tiene subEventId específico, agregarlo
        if (subEventId.isNotEmpty) {
          userSubEvents.putIfAbsent(userId, () => <String>{}).add(subEventId);
        } else {
          // Si está inscrito al programa, está inscrito en todas las actividades
          if (!userSubEvents.containsKey(userId)) {
            userSubEvents[userId] = {};
          }
          for (final subEvent in subEvents) {
            userSubEvents[userId]!.add(subEvent.subEventId);
          }
        }
      }

      // Obtener información de los usuarios y sus asistencias
      final inscritos = <Map<String, dynamic>>[];

      for (final userId in userIds) {
        // Obtener datos del usuario
        final userDoc = await _firestore.collection('users').doc(userId).get();
        if (!userDoc.exists) continue;

        final userData = userDoc.data() as Map<String, dynamic>;
        final displayName = userData['displayName'] as String? ?? 'Sin nombre';
        final studentCode = userData['studentCode'] as String? ?? '';
        // Si no hay código de estudiante, usar los últimos 8 caracteres del UID como código
        final codigo = studentCode.isNotEmpty ? studentCode : userId.substring(userId.length > 8 ? userId.length - 8 : 0);

        // Obtener asistencias validadas del usuario para este evento
        final attendanceQuery = await _firestore
            .collection('attendanceRecords')
            .where('userId', isEqualTo: userId)
            .where('baseEventId', isEqualTo: eventId)
            .where('status', isEqualTo: 'validated')
            .get();

        // Mapear asistencias a IDs de actividades (basado en subEventId)
        final asistencias = <int>{};
        
        for (final attDoc in attendanceQuery.docs) {
          final attData = attDoc.data();
          final subEventId = attData['subEventId'] as String? ?? '';
          
          // Buscar el índice de la actividad en la lista ordenada
          final index = subEvents.indexWhere((s) => s.subEventId == subEventId);
          if (index != -1) {
            asistencias.add(index + 1); // IDs empezando desde 1
          }
        }

        inscritos.add({
          'nombre': displayName,
          'codigo': codigo,
          'asistencias': asistencias.toList()..sort(),
        });
      }

      // Ordenar inscritos por nombre
      inscritos.sort((a, b) => (a['nombre'] as String).compareTo(b['nombre'] as String));

      // Preparar el body para la API
      final requestBody = {
        'tituloEvento': event.title,
        'actividades': actividades,
        'inscritos': inscritos,
      };

      // Realizar la petición POST
      final response = await http.post(
        Uri.parse('$_baseUrl/generar-reporte'),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
        },
        body: jsonEncode(requestBody),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('La solicitud al servidor tardó demasiado. Intenta nuevamente.');
        },
      );

      if (response.statusCode == 200) {
        // Retornar los bytes del PDF
        return response.bodyBytes;
      } else {
        throw Exception('Error al generar el reporte: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error al generar reporte de asistencia: $e');
    }
  }
}

