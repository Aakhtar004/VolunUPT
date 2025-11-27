import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';

class EventService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _eventsCollection = 'events';
  static const String _subEventsCollection = 'subEvents';
  static const String _registrationsCollection = 'registrations';

  // Obtener todos los eventos activos
  static Stream<List<EventModel>> getActiveEvents() {
    return _firestore
        .collection(_eventsCollection)
        .where('status', isEqualTo: EventStatus.publicado.toString().split('.').last)
        .snapshots()
        .asyncMap((snapshot) async {
          final events = snapshot.docs.map((doc) => EventModel.fromSnapshot(doc)).toList();
          final now = DateTime.now();
          final List<EventModel> pending = [];
          for (final e in events) {
            try {
              final subsQuery = await _firestore
                  .collection(_subEventsCollection)
                  .where('baseEventId', isEqualTo: e.eventId)
                  .get();
              if (subsQuery.docs.isEmpty) {
                pending.add(e);
                continue;
              }
              final subs = subsQuery.docs.map((d) => SubEventModel.fromSnapshot(d)).toList();
              final hasCompleted = subs.every((s) => s.endTime.isBefore(now));
              final hasStarted = subs.any((s) => !s.endTime.isBefore(now) && s.startTime.isBefore(now));
              if (!hasStarted && !hasCompleted) {
                pending.add(e);
              }
            } catch (_) {
              pending.add(e);
            }
          }
          return pending;
        });
  }

  // Obtener eventos por coordinador
  static Stream<List<EventModel>> getEventsByCoordinator(String coordinatorId) {
    return _firestore
        .collection(_eventsCollection)
        .where('coordinatorId', isEqualTo: coordinatorId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => EventModel.fromSnapshot(doc))
            .toList());
  }

  // Obtener evento por ID
  static Future<EventModel?> getEventById(String eventId) async {
    try {
      final doc = await _firestore
          .collection(_eventsCollection)
          .doc(eventId)
          .get();
      
      if (doc.exists) {
        return EventModel.fromSnapshot(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Error al obtener evento: $e');
    }
  }

  // Obtener subeventos de un evento
  static Stream<List<SubEventModel>> getSubEventsByEvent(String eventId) {
    // Nota: Para evitar requerir un índice compuesto (where + orderBy) en Firestore,
    // realizamos el ordenamiento por fecha en el cliente.
    return _firestore
        .collection(_subEventsCollection)
        .where('baseEventId', isEqualTo: eventId)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => SubEventModel.fromSnapshot(doc))
              .toList();
          list.sort((a, b) => a.date.compareTo(b.date));
          return list;
        });
  }

  // Obtener cantidad de subeventos por evento (consulta directa)
  static Future<int> getSubEventCountByEvent(String eventId) async {
    try {
      final query = await _firestore
          .collection(_subEventsCollection)
          .where('baseEventId', isEqualTo: eventId)
          .get();
      return query.docs.length;
    } catch (e) {
      throw Exception('Error al contar actividades: $e');
    }
  }

  // Obtener subeventos por coordinador (agregando todos los subeventos de sus programas)
  static Stream<List<SubEventModel>> getSubEventsByCoordinator(String coordinatorId) {
    return _firestore
        .collection(_eventsCollection)
        .where('coordinatorId', isEqualTo: coordinatorId)
        .snapshots()
        .asyncMap((eventsSnapshot) async {
          final eventIds = eventsSnapshot.docs.map((doc) => doc.id).toList();
          if (eventIds.isEmpty) {
            return <SubEventModel>[];
          }

          // Firestore limita whereIn a 10 elementos por consulta
          final List<SubEventModel> allSubEvents = [];
          for (int i = 0; i < eventIds.length; i += 10) {
            final chunk = eventIds.sublist(i, i + 10 > eventIds.length ? eventIds.length : i + 10);
            final subEventsQuery = await _firestore
                .collection(_subEventsCollection)
                .where('baseEventId', whereIn: chunk)
                .orderBy('date')
                .get();
            allSubEvents.addAll(subEventsQuery.docs.map((doc) => SubEventModel.fromSnapshot(doc)));
          }

          // Ordenar por fecha
          allSubEvents.sort((a, b) => a.date.compareTo(b.date));
          return allSubEvents;
        });
  }

  // Obtener subeventos disponibles para inscripción
  static Stream<List<SubEventModel>> getAvailableSubEvents() {
    final now = DateTime.now();
    return _firestore
        .collection(_subEventsCollection)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
        .orderBy('date')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SubEventModel.fromSnapshot(doc))
            .where((subEvent) => subEvent.registeredCount < subEvent.maxVolunteers)
            .toList());
  }

  // Verificar si un usuario está inscrito en un subevento
  static Future<bool> isUserRegistered(String userId, String subEventId) async {
    try {
      final query = await _firestore
          .collection(_registrationsCollection)
          .where('userId', isEqualTo: userId)
          .where('subEventId', isEqualTo: subEventId)
          .get();
      
      return query.docs.isNotEmpty;
    } catch (e) {
      throw Exception('Error al verificar inscripción: $e');
    }
  }
  // Verificar si un usuario está inscrito en el programa (evento base)
  static Future<bool> isUserRegisteredForEvent(String userId, String baseEventId) async {
    try {
      final query = await _firestore
          .collection(_registrationsCollection)
          .where('userId', isEqualTo: userId)
          .where('baseEventId', isEqualTo: baseEventId)
          .where('subEventId', isEqualTo: '')
          .get();
      return query.docs.isNotEmpty;
    } catch (e) {
      throw Exception('Error al verificar inscripción al programa: $e');
    }
  }

  // Inscribir usuario en subevento
  static Future<void> registerUserToSubEvent({
    required String userId,
    required String subEventId,
    required String baseEventId,
  }) async {
    try {
      // Evitar duplicados
      final existing = await _firestore
          .collection(_registrationsCollection)
          .where('userId', isEqualTo: userId)
          .where('subEventId', isEqualTo: subEventId)
          .limit(1)
          .get();
      if (existing.docs.isNotEmpty) {
        return; // Ya inscrito
      }

      final subDoc = await _firestore.collection(_subEventsCollection).doc(subEventId).get();
      if (!subDoc.exists) {
        throw Exception('La actividad no existe');
      }
      final subEvent = SubEventModel.fromSnapshot(subDoc);
      final now = DateTime.now();
      final hasEnded = subEvent.endTime.isBefore(now);
      final hasStarted = !hasEnded && subEvent.startTime.isBefore(now);
      if (hasStarted || hasEnded) {
        throw Exception('La actividad ya inició o finalizó');
      }
      if (subEvent.registeredCount >= subEvent.maxVolunteers) {
        throw Exception('La actividad está llena');
      }

      final batch = _firestore.batch();

      final registration = RegistrationModel(
        registrationId: '',
        userId: userId,
        subEventId: subEventId,
        baseEventId: baseEventId,
        registeredAt: DateTime.now(),
      );

      final registrationRef = _firestore.collection(_registrationsCollection).doc();
      batch.set(registrationRef, registration.toMap());

      final subEventRef = _firestore.collection(_subEventsCollection).doc(subEventId);
      batch.update(subEventRef, {
        'registeredCount': FieldValue.increment(1),
      });

      await batch.commit();
    } catch (e) {
      throw Exception('Error al inscribirse en el evento: $e');
    }
  }
  // Inscribir usuario al programa (evento base)
  static Future<void> registerUserToEvent({
    required String userId,
    required String baseEventId,
  }) async {
    try {
      // Evitar duplicados
      final existing = await _firestore
          .collection(_registrationsCollection)
          .where('userId', isEqualTo: userId)
          .where('baseEventId', isEqualTo: baseEventId)
          .where('subEventId', isEqualTo: '')
          .limit(1)
          .get();
      if (existing.docs.isNotEmpty) {
        return; // Ya inscrito al programa
      }

      // Bloquear inscripción si el evento ya inició
      final started = await hasEventStarted(baseEventId);
      if (started) {
        throw Exception('El programa ya inició, las inscripciones al programa están cerradas');
      }

      final registration = RegistrationModel(
        registrationId: '',
        userId: userId,
        subEventId: '',
        baseEventId: baseEventId,
        registeredAt: DateTime.now(),
      );
      await _firestore
          .collection(_registrationsCollection)
          .add(registration.toMap());
    } catch (e) {
      throw Exception('Error al inscribirse al programa: $e');
    }
  }

  // Cancelar inscripción de usuario
  static Future<void> unregisterUserFromSubEvent({
    required String userId,
    required String subEventId,
  }) async {
    try {
      final batch = _firestore.batch();

      final subDoc = await _firestore.collection(_subEventsCollection).doc(subEventId).get();
      if (!subDoc.exists) {
        throw Exception('La actividad no existe');
      }
      final subEvent = SubEventModel.fromSnapshot(subDoc);
      final now = DateTime.now();
      final hasEnded = subEvent.endTime.isBefore(now);
      final hasStarted = !hasEnded && subEvent.startTime.isBefore(now);
      if (hasStarted || hasEnded) {
        throw Exception('No se puede cancelar una actividad iniciada o finalizada');
      }

      // Buscar y eliminar registro de inscripción
      final registrationQuery = await _firestore
          .collection(_registrationsCollection)
          .where('userId', isEqualTo: userId)
          .where('subEventId', isEqualTo: subEventId)
          .get();

      if (registrationQuery.docs.isNotEmpty) {
        final registrationDoc = registrationQuery.docs.first;
        batch.delete(registrationDoc.reference);

        final subEventRef = _firestore.collection(_subEventsCollection).doc(subEventId);
        batch.update(subEventRef, {
          'registeredCount': FieldValue.increment(-1),
        });

        await batch.commit();
      }
    } catch (e) {
      throw Exception('Error al cancelar inscripción: $e');
    }
  }
  // Cancelar inscripción del usuario al programa (evento base)
  static Future<void> unregisterUserFromEvent({
    required String userId,
    required String baseEventId,
  }) async {
    try {
      // Bloquear cancelación si el evento ya inició
      final started = await hasEventStarted(baseEventId);
      if (started) {
        throw Exception('No se puede cancelar una inscripción del programa iniciado');
      }
      final query = await _firestore
          .collection(_registrationsCollection)
          .where('userId', isEqualTo: userId)
          .where('baseEventId', isEqualTo: baseEventId)
          .where('subEventId', isEqualTo: '')
          .get();
      for (final doc in query.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      throw Exception('Error al cancelar inscripción al programa: $e');
    }
  }

  // Determinar si el programa ya inició (si cualquier actividad ha comenzado)
  static Future<bool> hasEventStarted(String baseEventId) async {
    try {
      final subEventsQuery = await _firestore
          .collection(_subEventsCollection)
          .where('baseEventId', isEqualTo: baseEventId)
          .get();
      final now = DateTime.now();
      for (final doc in subEventsQuery.docs) {
        final s = SubEventModel.fromSnapshot(doc);
        final hasEnded = s.endTime.isBefore(now);
        final hasStarted = !hasEnded && s.startTime.isBefore(now);
        if (hasStarted) return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Determinar si el programa ya finalizó (todas las actividades terminaron)
  static Future<bool> hasEventCompleted(String baseEventId) async {
    try {
      final subEventsQuery = await _firestore
          .collection(_subEventsCollection)
          .where('baseEventId', isEqualTo: baseEventId)
          .get();
      if (subEventsQuery.docs.isEmpty) return false;
      final now = DateTime.now();
      for (final doc in subEventsQuery.docs) {
        final s = SubEventModel.fromSnapshot(doc);
        if (!s.endTime.isBefore(now)) {
          return false;
        }
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  // Obtener inscripciones de un usuario
  static Stream<List<RegistrationModel>> getUserRegistrations(String userId) {
    // Evitar requerir índice compuesto: ordenar en memoria
    return _firestore
        .collection(_registrationsCollection)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs.map((doc) => RegistrationModel.fromSnapshot(doc)).toList();
          list.sort((a, b) => b.registeredAt.compareTo(a.registeredAt));
          return list;
        });
  }

  // Obtener inscripciones de un subevento
  static Stream<List<RegistrationModel>> getSubEventRegistrations(String subEventId) {
    // Evitamos requerir un índice compuesto eliminando orderBy de Firestore y ordenando en memoria.
    return _firestore
        .collection(_registrationsCollection)
        .where('subEventId', isEqualTo: subEventId)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => RegistrationModel.fromSnapshot(doc))
              .toList();
          list.sort((a, b) => a.registeredAt.compareTo(b.registeredAt));
          return list;
        });
  }
  // Obtener inscripciones del programa (evento base)
  static Stream<List<RegistrationModel>> getEventRegistrations(String baseEventId) {
    return _firestore
        .collection(_registrationsCollection)
        .where('baseEventId', isEqualTo: baseEventId)
        .where('subEventId', isEqualTo: '')
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => RegistrationModel.fromSnapshot(doc))
              .toList();
          list.sort((a, b) => a.registeredAt.compareTo(b.registeredAt));
          return list;
        });
  }

  // Obtener inscripciones del usuario a subeventos de un evento base
  static Future<List<RegistrationModel>> getUserSubEventRegistrationsForEvent({
    required String userId,
    required String baseEventId,
  }) async {
    try {
      final query = await _firestore
          .collection(_registrationsCollection)
          .where('userId', isEqualTo: userId)
          .where('baseEventId', isEqualTo: baseEventId)
          .get();
      return query.docs
          .map((doc) => RegistrationModel.fromSnapshot(doc))
          .where((reg) => reg.subEventId.isNotEmpty)
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Obtener todas las inscripciones ligadas a un programa (incluye subeventos y programa base)
  static Stream<List<RegistrationModel>> getAllRegistrationsByEvent(String baseEventId) {
    return _firestore
        .collection(_registrationsCollection)
        .where('baseEventId', isEqualTo: baseEventId)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => RegistrationModel.fromSnapshot(doc))
              .toList();
          list.sort((a, b) => a.registeredAt.compareTo(b.registeredAt));
          return list;
        });
  }

  // Crear nuevo evento (solo coordinadores/administradores)
  static Future<String> createEvent({
    required String title,
    required String description,
    required String coordinatorId,
    required double totalHoursForCertificate,
    String? imageUrl,
    SessionType sessionType = SessionType.multiple,
    // Datos opcionales para crear automáticamente la primera actividad
    DateTime? singleSessionDate,
    DateTime? singleSessionStartTime,
    DateTime? singleSessionEndTime,
    String? singleSessionLocation,
    double? singleSessionLatitude,
    double? singleSessionLongitude,
    int? singleSessionMaxVolunteers,
  }) async {
    try {
      final event = EventModel(
        eventId: '', // Se asignará automáticamente
        title: title,
        description: description,
        imageUrl: imageUrl ?? '',
        coordinatorId: coordinatorId,
        status: EventStatus.borrador,
        totalHoursForCertificate: totalHoursForCertificate,
        sessionType: sessionType,
      );

      final docRef = await _firestore
          .collection(_eventsCollection)
          .add(event.toMap());

      // Si el programa es de una sola sesión, crear automáticamente la primera actividad
      if (sessionType == SessionType.unica) {
        // Validar datos de la sesión única
        if (singleSessionDate == null ||
            singleSessionStartTime == null ||
            singleSessionEndTime == null ||
            (singleSessionLocation == null || singleSessionLocation.trim().isEmpty) ||
            (singleSessionMaxVolunteers == null || singleSessionMaxVolunteers <= 0)) {
          // Si faltan datos, eliminar el programa recién creado para evitar registros incompletos
          try {
            await _firestore.collection(_eventsCollection).doc(docRef.id).delete();
          } catch (_) {}
          throw Exception('Faltan datos de la sesión única (fecha, horas, ubicación o cupo).');
        }

        await createSubEvent(
          baseEventId: docRef.id,
          title: 'Sesión única',
          date: singleSessionDate,
          startTime: singleSessionStartTime,
          endTime: singleSessionEndTime,
          location: singleSessionLocation,
          latitude: singleSessionLatitude,
          longitude: singleSessionLongitude,
          maxVolunteers: singleSessionMaxVolunteers,
        );
      }

      return docRef.id;
    } catch (e) {
      throw Exception('Error al crear evento: $e');
    }
  }

  // Crear subevento
  static Future<String> createSubEvent({
    required String baseEventId,
    required String title,
    required DateTime date,
    required DateTime startTime,
    required DateTime endTime,
    required String location,
    double? latitude,
    double? longitude,
    required int maxVolunteers,
  }) async {
    try {
      final subEvent = SubEventModel(
        subEventId: '', // Se asignará automáticamente
        baseEventId: baseEventId,
        title: title,
        date: date,
        startTime: startTime,
        endTime: endTime,
        location: location,
        latitude: latitude,
        longitude: longitude,
        maxVolunteers: maxVolunteers,
        registeredCount: 0,
        qrCodeData: '', // Se generará después
      );

      final docRef = await _firestore
          .collection(_subEventsCollection)
          .add(subEvent.toMap());

      // Generar QR code data
      final qrCodeData = 'subevent:${docRef.id}:${DateTime.now().millisecondsSinceEpoch}';
      await docRef.update({'qrCodeData': qrCodeData});

      // Auto-publicar el programa si está en borrador
      try {
        final eventDoc = await _firestore.collection(_eventsCollection).doc(baseEventId).get();
        if (eventDoc.exists) {
          final statusStr = (eventDoc.data() ?? {})['status'] as String?;
          if (statusStr == EventStatus.borrador.toString().split('.').last) {
            await _firestore
                .collection(_eventsCollection)
                .doc(baseEventId)
                .update({'status': EventStatus.publicado.toString().split('.').last});
          }
        }
      } catch (_) {
        // No bloquear creación por fallo en auto-publicación
      }

      return docRef.id;
    } catch (e) {
      throw Exception('Error al crear subevento: $e');
    }
  }

  // Actualizar estado de evento
  static Future<void> updateEventStatus(String eventId, EventStatus status) async {
    try {
      await _firestore
          .collection(_eventsCollection)
          .doc(eventId)
          .update({'status': status.toString().split('.').last});
    } catch (e) {
      throw Exception('Error al actualizar estado del evento: $e');
    }
  }

  // Actualizar datos de un evento
  static Future<void> updateEvent({
    required String eventId,
    required String title,
    required String description,
    String? imageUrl,
    double? totalHoursForCertificate,
    EventStatus? status,
  }) async {
    try {
      final Map<String, dynamic> data = {
        'title': title,
        'description': description,
      };

      if (imageUrl != null) data['imageUrl'] = imageUrl;
      if (totalHoursForCertificate != null) {
        data['totalHoursForCertificate'] = totalHoursForCertificate;
      }
      if (status != null) {
        data['status'] = status.toString().split('.').last;
      }

      await _firestore.collection(_eventsCollection).doc(eventId).update(data);
    } catch (e) {
      throw Exception('Error al actualizar evento: $e');
    }
  }

  // Eliminar evento
  static Future<void> deleteEvent(String eventId) async {
    try {
      final batch = _firestore.batch();

      // Eliminar evento
      final eventRef = _firestore.collection(_eventsCollection).doc(eventId);
      batch.delete(eventRef);

      // Eliminar subeventos relacionados
      final subEvents = await _firestore
          .collection(_subEventsCollection)
          .where('baseEventId', isEqualTo: eventId)
          .get();

      for (final doc in subEvents.docs) {
        batch.delete(doc.reference);
      }

      // Eliminar inscripciones relacionadas
      final registrations = await _firestore
          .collection(_registrationsCollection)
          .where('baseEventId', isEqualTo: eventId)
          .get();

      for (final doc in registrations.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Error al eliminar evento: $e');
    }
  }

  // Actualizar datos de un subevento
  static Future<void> updateSubEvent({
    required String subEventId,
    required String title,
    required DateTime date,
    required DateTime startTime,
    required DateTime endTime,
    required String location,
    double? latitude,
    double? longitude,
    required int maxVolunteers,
  }) async {
    try {
      final Map<String, dynamic> data = {
        'title': title,
        'date': Timestamp.fromDate(date),
        'startTime': Timestamp.fromDate(startTime),
        'endTime': Timestamp.fromDate(endTime),
        'location': location,
        'latitude': latitude,
        'longitude': longitude,
        'maxVolunteers': maxVolunteers,
      };

      await _firestore.collection(_subEventsCollection).doc(subEventId).update(data);
    } catch (e) {
      throw Exception('Error al actualizar subevento: $e');
    }
  }

  // Eliminar subevento
  static Future<void> deleteSubEvent(String subEventId) async {
    try {
      final batch = _firestore.batch();

      // Eliminar subevento
      final subEventRef = _firestore.collection(_subEventsCollection).doc(subEventId);
      batch.delete(subEventRef);

      // Eliminar inscripciones relacionadas a este subevento
      final registrations = await _firestore
          .collection(_registrationsCollection)
          .where('subEventId', isEqualTo: subEventId)
          .get();

      for (final doc in registrations.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Error al eliminar subevento: $e');
    }
  }

  // Obtener un subevento por ID
  static Future<SubEventModel?> getSubEventById(String subEventId) async {
    try {
      final doc = await _firestore
          .collection(_subEventsCollection)
          .doc(subEventId)
          .get();
      
      if (doc.exists) {
        return SubEventModel.fromSnapshot(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Error al obtener subevento: $e');
    }
  }

  // Conteos para estadísticas
  static Future<int> countEventsByCoordinator(String coordinatorId) async {
    final q = await _firestore
        .collection(_eventsCollection)
        .where('coordinatorId', isEqualTo: coordinatorId)
        .get();
    return q.docs.length;
  }

  static Future<int> countPublishedEvents() async {
    final q = await _firestore
        .collection(_eventsCollection)
        .where('status', isEqualTo: EventStatus.publicado.toString().split('.').last)
        .get();
    return q.docs.length;
  }

  static Future<int> countSubEventsByCoordinator(String coordinatorId) async {
    final events = await _firestore
        .collection(_eventsCollection)
        .where('coordinatorId', isEqualTo: coordinatorId)
        .get();

    final eventIds = events.docs.map((d) => d.id).toList();
    if (eventIds.isEmpty) return 0;

    int total = 0;
    const chunkSize = 10;
    for (var i = 0; i < eventIds.length; i += chunkSize) {
      final chunk = eventIds.sublist(i, i + chunkSize > eventIds.length ? eventIds.length : i + chunkSize);
      final q = await _firestore
          .collection(_subEventsCollection)
          .where('baseEventId', whereIn: chunk)
          .get();
      total += q.docs.length;
    }
    return total;
  }

  static Future<int> countRegistrationsByCoordinator(String coordinatorId) async {
    final events = await _firestore
        .collection(_eventsCollection)
        .where('coordinatorId', isEqualTo: coordinatorId)
        .get();
    final eventIds = events.docs.map((d) => d.id).toList();
    if (eventIds.isEmpty) return 0;

    int total = 0;
    const chunkSize = 10;
    for (var i = 0; i < eventIds.length; i += chunkSize) {
      final chunk = eventIds.sublist(i, i + chunkSize > eventIds.length ? eventIds.length : i + chunkSize);
      final q = await _firestore
          .collection(_registrationsCollection)
          .where('baseEventId', whereIn: chunk)
          .get();
      total += q.docs.length;
    }
    return total;
  }
}